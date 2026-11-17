package com.pausa.pausa_app

import android.accessibilityservice.AccessibilityService
import android.accessibilityservice.AccessibilityServiceInfo
import android.app.usage.UsageEvents
import android.app.usage.UsageStatsManager
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.os.Handler
import android.os.Looper
import android.view.accessibility.AccessibilityEvent

class PausaAccessibilityService : AccessibilityService() {

    private var lastForegroundPackage = ""

    // Tras (re)conectar el servicio, el primer tic busca la app que está delante
    // en una ventana larga: si el proceso estuvo muerto unos segundos, la app
    // bloqueada pudo abrirse antes y ya no aparece en la ventana corta de 2 s.
    private var needsLongLookup = false
    // Resultado de esa búsqueda, válido unos segundos para que el tic siguiente
    // pueda disparar el intercept pendiente aunque no haya eventos nuevos.
    private var stickyForeground: String? = null
    private var stickyUntilMs = 0L

    private val handler = Handler(Looper.getMainLooper())

    private val screenReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context?, intent: Intent?) {
            when (intent?.action) {
                Intent.ACTION_SCREEN_OFF -> onScreenOff()
                Intent.ACTION_SCREEN_ON -> {
                    PausaLog.d("PausaDebug", "pantalla encendida — reiniciando poller")
                    // Sentinel forces the next poller tick to evaluate whatever app is in
                    // foreground, even if it was already there before the screen turned off.
                    // The session ended when the screen went off, so the app has no
                    // active session and pendingIntercepts will re-trigger the countdown.
                    lastForegroundPackage = "__reset__"
                    handler.removeCallbacks(foregroundPoller)
                    handler.postDelayed(foregroundPoller, 500)
                }
                Intent.ACTION_USER_PRESENT -> {
                    // Tras desbloquear, la app que estaba debajo vuelve a quedar delante.
                    // La búsqueda larga la encuentra aunque su evento ya no entre en la
                    // ventana corta del poller.
                    PausaLog.d("PausaDebug", "móvil desbloqueado — reevaluando la app delante")
                    lastForegroundPackage = "__reset__"
                    needsLongLookup = true
                    handler.removeCallbacks(foregroundPoller)
                    handler.postDelayed(foregroundPoller, 500)
                }
            }
        }
    }

    // Apagar la pantalla cuenta como salir de la app: se cierra la sesión (el uso
    // se suma hasta este momento) y se cancela la cuenta atrás si estaba en marcha.
    // Sin esto el temporizador seguía corriendo con el móvil bloqueado y expulsaba
    // —con bloqueo hasta medianoche— por tiempo que nadie había usado.
    private fun onScreenOff() {
        val sessions = activeSessionApps.toList()
        PausaLog.d("PausaDebug", "pantalla apagada — cerrando sesiones: $sessions / temporizador: ${PausaTimerService.currentPackage}")
        PausaInterstitialActivity.cancelForScreenOff()
        PausaTimerService.stopAll()
        sessions.forEach { endSession(it) }
        pendingIntercepts.clear()
        stopWatchingInterstitial("pantalla apagada")
        lastForegroundPackage = ""
    }

    private fun launchInterstitial(pkg: String, pausaConfig: Triple<String, Int, Int>) {
        startActivity(Intent(this, PausaInterstitialActivity::class.java).apply {
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            addFlags(Intent.FLAG_ACTIVITY_CLEAR_TOP)
            addFlags(Intent.FLAG_ACTIVITY_SINGLE_TOP)
            addFlags(Intent.FLAG_ACTIVITY_REORDER_TO_FRONT)
            putExtra("packageName", pkg)
            putExtra("appName", pausaConfig.first)
            putExtra("waitSeconds", pausaConfig.second)
            putExtra("maxMinutes", pausaConfig.third)
            putExtra("userInitiated", true)
        })
    }

    // ── Vigilancia de la pantalla de espera ───────────────────────────────────
    // Lanzar la pantalla de espera no garantiza que salga: HyperOS la deja
    // detrás si el lanzamiento cae en plena animación de apertura de la app
    // ("avoidMoveToFront by anim effect", visto en logcat el 16-11). Tras cada
    // lanzamiento se comprueba que está visible y, si no, se reintenta; si a
    // los 10 s sigue sin salir, se manda al inicio. La app nunca debe quedarse
    // abierta sin pausa.
    private var awaitingPkg = ""
    private var awaitingSinceMs = 0L

    private fun watchInterstitial(pkg: String) {
        awaitingPkg = pkg
        awaitingSinceMs = System.currentTimeMillis()
        handler.removeCallbacks(interstitialWatchdog)
        handler.postDelayed(interstitialWatchdog, INTERSTITIAL_FIRST_RETRY_MS)
    }

    private fun stopWatchingInterstitial(reason: String) {
        if (awaitingPkg.isNotEmpty()) {
            PausaLog.d("PausaDebug", "vigilancia de la espera de $awaitingPkg terminada: $reason")
        }
        awaitingPkg = ""
        handler.removeCallbacks(interstitialWatchdog)
    }

    private val interstitialWatchdog: Runnable = object : Runnable {
        override fun run() {
            val pkg = awaitingPkg
            if (pkg.isEmpty()) return

            // La espera ya está en pantalla (o ya terminó y hay sesión): hecho.
            // No se relanza con la pantalla visible, así nunca hay dos a la vez
            // ni se reinicia una cuenta atrás en marcha.
            if (PausaInterstitialActivity.visiblePackage == pkg || isInActiveSession(pkg)) {
                stopWatchingInterstitial("confirmada")
                return
            }
            val interactive =
                (getSystemService(Context.POWER_SERVICE) as android.os.PowerManager).isInteractive
            val config = getPausaForPackage(pkg)
            if (!interactive || config == null || isExpelling ||
                wasRecentlyExpelled(pkg) || isInDailyCooldown(pkg)) {
                stopWatchingInterstitial("ya no aplica")
                return
            }

            val front = ForegroundHelper.lastForegroundPackage(this@PausaAccessibilityService)
            if (front != null && front != pkg) {
                stopWatchingInterstitial("delante hay otra cosa ($front)")
                return
            }

            val waited = System.currentTimeMillis() - awaitingSinceMs
            if (waited >= INTERSTITIAL_GIVE_UP_MS) {
                if (front == pkg) {
                    PausaLog.d("PausaDebug", "la espera de $pkg no ha salido en ${waited}ms — al inicio")
                    if (!performGlobalAction(GLOBAL_ACTION_HOME)) {
                        startActivity(Intent(Intent.ACTION_MAIN).apply {
                            addCategory(Intent.CATEGORY_HOME)
                            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                        })
                    }
                    lastForegroundPackage = ""
                }
                stopWatchingInterstitial("tiempo agotado")
                return
            }

            if (front == pkg) {
                PausaLog.d("PausaDebug", "la espera de $pkg no ha salido tras ${waited}ms — reintento")
                launchInterstitial(pkg, config)
            }
            handler.postDelayed(this, INTERSTITIAL_RETRY_MS)
        }
    }

    private var lastBlockedToastMs = 0L

    /** Aviso al abrir una app con el tiempo de hoy agotado (como mucho uno cada 5 s). */
    private fun showBlockedToast(pkg: String) {
        val now = System.currentTimeMillis()
        if (now - lastBlockedToastMs < 5000L) return
        lastBlockedToastMs = now
        val name = getPausaForPackage(pkg)?.first ?: return
        try {
            android.widget.Toast.makeText(
                applicationContext,
                "Has agotado tu tiempo de $name por hoy",
                android.widget.Toast.LENGTH_LONG
            ).show()
        } catch (e: Exception) {
            PausaLog.e("PausaDebug", "no se pudo mostrar el aviso de bloqueo: $e")
        }
    }

    // Polls UsageStats every second as a backup — catches resumptions that
    // don't fire a strong enough AccessibilityEvent (e.g. task resume).
    private val foregroundPoller = object : Runnable {
        override fun run() {
            val current = resolveForegroundApp() ?: run {
                handler.postDelayed(this, 1000)
                return
            }
            PausaLog.d("PausaDebug", "poller — current: $current / last: $lastForegroundPackage / isExpelling: $isExpelling / pending: ${pendingIntercepts.keys}")

            // PAUSA itself came to foreground — do NOT stop timer here.
            // MainActivity.onResume handles this exclusively via PausaTimerService.stopAll()
            // so there is exactly one stop path and no race condition.
            if (current == applicationContext.packageName ||
                current.startsWith("com.pausa.")) {
                lastForegroundPackage = current
                handler.postDelayed(this, 1000)
                return
            }

            // Home or task switcher — handle and force-reset lastForegroundPackage so
            // the next app open is always detected as a new event.
            if (current in homeAndLauncherPackages || current in taskSwitcherPackages) {
                handleAppChange(current)
                lastForegroundPackage = ""
                handler.postDelayed(this, 1000)
                return
            }

            // Daily cooldown active — push home on every tick so MIUI can't relaunch the app.
            // This runs before pendingIntercepts so the intercept never gets queued at all.
            if (current !in ignoredPackages &&
                current !in homeAndLauncherPackages &&
                current !in taskSwitcherPackages &&
                getPausaForPackage(current) != null &&
                isInDailyCooldown(current)) {
                if (current != lastForegroundPackage) {
                    PausaLog.d("PausaDebug", "poller — daily cooldown active for $current, sending home")
                }
                showBlockedToast(current)
                startActivity(Intent(Intent.ACTION_MAIN).apply {
                    addCategory(Intent.CATEGORY_HOME)
                    addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                })
                handler.postDelayed(this, 1000)
                return
            }

            // Process pending intercepts — fire when the target app is confirmed foreground
            val now = System.currentTimeMillis()
            val iter = pendingIntercepts.iterator()
            while (iter.hasNext()) {
                val (pkg, deadline) = iter.next()
                if (now > deadline) {
                    PausaLog.d("PausaDebug", "PENDING intercept expired for $pkg")
                    iter.remove()
                    continue
                }
                if (current == pkg) {
                    iter.remove()
                    PausaLog.d("PausaDebug", "PENDING intercept for $pkg — wasRecentlyExpelled: ${wasRecentlyExpelled(pkg)} / isInDailyCooldown: ${isInDailyCooldown(pkg)}")
                    if (wasRecentlyExpelled(pkg) || isInDailyCooldown(pkg)) {
                        // Still in expulsion/cooldown window — send straight home
                        PausaLog.d("PausaDebug", "PENDING intercept blocked — daily cooldown active for $pkg")
                        startActivity(Intent(Intent.ACTION_MAIN).apply {
                            addCategory(Intent.CATEGORY_HOME)
                            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                        })
                    } else if (!isInActiveSession(pkg) && !isExpelled(pkg) && !isExpelling) {
                        val pausaConfig = getPausaForPackage(pkg) ?: continue
                        PausaLog.d("PausaDebug", "PENDING intercept firing for $pkg")
                        lastForegroundPackage = pkg
                        launchInterstitial(pkg, pausaConfig)
                        watchInterstitial(pkg)
                    }
                }
            }

            if (current != lastForegroundPackage) {
                handleAppChange(current)
                lastForegroundPackage = current
            }
            handler.postDelayed(this, 1000)
        }
    }

    companion object {
        private const val INTERSTITIAL_FIRST_RETRY_MS = 700L
        private const val INTERSTITIAL_RETRY_MS = 1000L
        private const val INTERSTITIAL_GIVE_UP_MS = 10_000L

        private val activeSessionApps = mutableSetOf<String>()
        private val expelledApps = mutableMapOf<String, Long>()
        // pkg -> deadline ms: packages waiting to be confirmed in foreground before intercept
        val pendingIntercepts = mutableMapOf<String, Long>()

        // Package currently being timed — used to cancel the timer on voluntary exit.
        var activeTimerPackage: String = ""

        // Tracks the last expelled package with a timestamp — survives beyond the
        // expelledApps window (which only gates the poller) to also gate the interstitial.
        var lastExpelledPackage: String = ""
        var lastExpelledTimeMs: Long = 0L

        // Application context stored on service connect so companion functions can
        // reach SharedPreferences without requiring a Context parameter.
        // Set before any companion function that uses it is called.
        private var appContext: Context? = null

        // True solo mientras el sistema tiene el servicio enlazado en este proceso.
        // El ajuste de Accesibilidad puede decir "activado" con el servicio caído
        // (p. ej. tras matar HyperOS el proceso); esto dice si funciona de verdad.
        @Volatile
        var isConnected = false
            private set

        fun startSession(packageName: String) {
            activeSessionApps.add(packageName)
            expelledApps.remove(packageName)
            pendingIntercepts.remove(packageName) // no longer needs intercepting
            activeTimerPackage = packageName
            // Clear persisted expulsion for this package — the user completed the countdown
            // and is legitimately entering the app, so expulsion state is no longer relevant.
            if (lastExpelledPackage == packageName) {
                lastExpelledPackage = ""
                lastExpelledTimeMs = 0L
                appContext?.getSharedPreferences("pausa_prefs", Context.MODE_PRIVATE)
                    ?.edit()
                    ?.remove("last_expelled_pkg")
                    ?.remove("last_expelled_ms")
                    ?.apply()
            }
        }

        /** Vuelve a marcar una sesión recuperada del disco, sin tocar el estado de expulsión. */
        fun restoreSession(packageName: String) {
            activeSessionApps.add(packageName)
            pendingIntercepts.remove(packageName)
            activeTimerPackage = packageName
        }

        fun endSession(packageName: String) {
            activeSessionApps.remove(packageName)
            expelledApps.remove(packageName)
            if (activeTimerPackage == packageName) activeTimerPackage = ""
        }

        fun markExpelled(packageName: String) {
            isExpelling = true
            lastExpelledPackage = packageName
            lastExpelledTimeMs = System.currentTimeMillis()
            PausaLog.d("PausaDebug", "markExpelled called for $packageName — setting lastExpelledTimeMs=$lastExpelledTimeMs")
            // Persist so it survives process restart (MIUI kills and restarts the process)
            if (appContext == null) {
                PausaLog.e("PausaDebug", "markExpelled — appContext is NULL, cannot persist expelled state!")
            } else {
                // El bloqueo del resto del día ya no es una marca aparte: sale del
                // uso acumulado (ver isInDailyCooldown).
                appContext!!.getSharedPreferences("pausa_prefs", Context.MODE_PRIVATE)
                    .edit()
                    .putString("last_expelled_pkg", packageName)
                    .putLong("last_expelled_ms", lastExpelledTimeMs)
                    .apply()
                PausaLog.d("PausaDebug", "markExpelled — persisted to prefs OK for $packageName")
            }
            activeSessionApps.remove(packageName)
            expelledApps[packageName] = System.currentTimeMillis() + 30000L // 30s window
            pendingIntercepts.remove(packageName)
            // Reset global expulsion guard after 10 seconds — only affects isExpelling,
            // not expelledApps (which runs for 30s) or wasRecentlyExpelled (30s).
            Handler(Looper.getMainLooper()).postDelayed({ isExpelling = false }, 10000)
        }

        fun isInActiveSession(packageName: String): Boolean =
            packageName in activeSessionApps

        fun isExpelled(packageName: String): Boolean {
            val expiry = expelledApps[packageName] ?: return false
            if (System.currentTimeMillis() > expiry) {
                expelledApps.remove(packageName)
                return false
            }
            return true
        }

        fun wasRecentlyExpelled(packageName: String): Boolean {
            // Prefer in-memory values; fall back to SharedPreferences if in-memory was reset
            // by a process restart (MIUI kills and restarts the accessibility service process).
            val ctx = appContext
            val savedPkg = if (lastExpelledPackage.isEmpty() && ctx != null)
                ctx.getSharedPreferences("pausa_prefs", Context.MODE_PRIVATE)
                    .getString("last_expelled_pkg", "") ?: ""
            else lastExpelledPackage
            val savedMs = if (lastExpelledTimeMs == 0L && ctx != null)
                ctx.getSharedPreferences("pausa_prefs", Context.MODE_PRIVATE)
                    .getLong("last_expelled_ms", 0L)
            else lastExpelledTimeMs
            if (savedPkg != packageName) return false
            val diff = System.currentTimeMillis() - savedMs
            val result = diff < 30000L
            PausaLog.d("PausaDebug", "wasRecentlyExpelled($packageName) — savedPkg=$savedPkg savedMs=$savedMs diff=${diff}ms result=$result")
            return result
        }

        /**
         * Saltar el bloqueo desde Pausa: concede 5 minutos extra hoy. No reinicia
         * el contador de uso del día.
         */
        fun resetDailyCooldown(context: Context, packageName: String) {
            val maxMinutes = SessionStore.configuredMaxMinutes(context, packageName) ?: 0
            if (maxMinutes > 0) {
                SessionStore.grantExtraToday(
                    context, packageName, maxMinutes, SessionStore.SKIP_EXTRA_SECONDS
                )
            }
            // Also clear the expelled state so the user can enter immediately
            expelledApps.remove(packageName)
            if (lastExpelledPackage == packageName) {
                lastExpelledPackage = ""
                lastExpelledTimeMs = 0L
                appContext?.getSharedPreferences("pausa_prefs", Context.MODE_PRIVATE)
                    ?.edit()
                    ?.remove("last_expelled_pkg")
                    ?.remove("last_expelled_ms")
                    ?.apply()
            }
            PausaLog.d("PausaDebug", "resetDailyCooldown — 5 min extra para $packageName")
        }

        /**
         * Bloqueada por hoy: lo usado hoy ha alcanzado el máximo actual de la
         * pausa (más el extra de saltar el bloqueo). Se calcula cada vez, así
         * que cambiar el máximo o el cambio de día se aplican solos.
         */
        fun isInDailyCooldown(packageName: String, context: Context? = appContext): Boolean {
            val ctx = context ?: return false
            val maxMinutes = SessionStore.configuredMaxMinutes(ctx, packageName) ?: return false
            if (maxMinutes <= 0) return false // sin límite
            return SessionStore.remainingSecondsToday(ctx, packageName, maxMinutes) <= 0
        }

        // Call from onServiceConnected to wipe stale state after a service restart.
        // IMPORTANT: does NOT touch lastExpelledPackage/Ms or their SharedPreferences keys —
        // those are restored from prefs before clearAll is called and must survive to block
        // re-entry after MIUI kills and restarts the process.
        fun clearAll() {
            activeSessionApps.clear()
            expelledApps.clear()
            pendingIntercepts.clear()
            isExpelling = false
            val ctx = appContext
            val preservedPkg = ctx?.getSharedPreferences("pausa_prefs", Context.MODE_PRIVATE)
                ?.getString("last_expelled_pkg", "") ?: "(no ctx)"
            val preservedMs = ctx?.getSharedPreferences("pausa_prefs", Context.MODE_PRIVATE)
                ?.getLong("last_expelled_ms", 0L) ?: -1L
            PausaLog.d("PausaDebug", "clearAll — preserving expelled prefs: pkg=$preservedPkg ms=$preservedMs")
        }

        // True for 10 seconds after any expulsion — blocks all intercepts globally
        // to prevent the crash loop caused by our own app coming to foreground.
        var isExpelling = false
            private set
    }

    private val ignoredPackages = setOf(
        "com.pausa.pausa_app",
        // SystemUI = status bar + notification shade, NOT a task switcher.
        // On MIUI, swiping down the notification shade fires SystemUI events —
        // keeping it here (not in taskSwitcherPackages) prevents session kills.
        "com.android.systemui",
        "android",
        "com.android.settings",
        "com.android.phone",
        "com.android.inputmethod.latin",
        // MIUI system UI surfaces — appear on notification shade swipe, screenshot, etc.
        "miui.systemui.plugin",
        "com.miui.systemui",
        "com.miui.notificationmanager",
        "com.miui.securitycenter",
        "com.miui.screenshot",
        "com.miui.mediaviewer",
    )

    private val homeAndLauncherPackages = setOf(
        // Stock Android
        "com.android.launcher",
        "com.android.launcher2",
        "com.android.launcher3",
        // Pixel / Google
        "com.google.android.apps.nexuslauncher",
        // Xiaomi / MIUI
        "com.miui.home",
        // Samsung / One UI
        "com.sec.android.app.launcher",
        "com.samsung.android.app.spage",
        // OnePlus / OxygenOS
        "net.oneplus.launcher",
        "com.oneplus.launcher",
        // Oppo / ColorOS
        "com.oppo.launcher",
        "com.coloros.launcher",
        // Realme / Realme UI
        "com.realme.launcher",
        // Vivo / Funtouch / OriginOS
        "com.vivo.launcher",
        "com.bbk.launcher2",
        // Huawei / EMUI / HarmonyOS
        "com.huawei.android.launcher",
        // LG
        "com.lge.launcher3",
        // Sony
        "com.sonyericsson.home",
        "com.sony.xperia.launcher",
        // HTC
        "com.htc.launcher",
        // Nokia
        "com.nokia.launcher",
        // Asus / ROG
        "com.asus.launcher",
        "com.asus.launcher3",
        // Nothing Phone
        "com.nothing.launcher",
        // Transsion (itel, Tecno, Infinix)
        "com.transsion.launcher",
    )

    private val taskSwitcherPackages = setOf(
        // com.android.systemui intentionally excluded — it fires on notification shade
        // swipe too, which would kill sessions. Moved to ignoredPackages instead.
        // MIUI recents is part of the home package
        "com.miui.home",
        // Samsung
        "com.sec.android.app.launcher",
        // Huawei
        "com.huawei.android.launcher",
        // OnePlus
        "net.oneplus.launcher",
        "com.oneplus.launcher",
        // Oppo / Realme
        "com.oppo.launcher",
        "com.coloros.launcher",
        "com.realme.launcher",
    )

    override fun onServiceConnected() {
        // ── Step 1: context — MUST be absolute first line so every companion
        //            function that calls getSharedPreferences has a valid context.
        appContext = applicationContext
        isConnected = true

        // ── Step 2: restore expelled state from prefs BEFORE clearAll() so the
        //            in-memory values are populated when clearAll's log reads them.
        //            MIUI kills and restarts the process after expulsion, resetting
        //            all companion-object vars to their default values.
        val prefs = getSharedPreferences("pausa_prefs", Context.MODE_PRIVATE)
        lastExpelledPackage = prefs.getString("last_expelled_pkg", "") ?: ""
        lastExpelledTimeMs = prefs.getLong("last_expelled_ms", 0L)
        val today = java.text.SimpleDateFormat("yyyyMMdd", java.util.Locale.getDefault())
            .format(java.util.Date())
        PausaLog.d("PausaDebug", "onServiceConnected — today=$today restored lastExpelledPkg=$lastExpelledPackage lastExpelledMs=$lastExpelledTimeMs")

        // ── Step 3: clear session state (but NOT expelled prefs — see clearAll()).
        // Only clear state if no timer is running. If a session is active (user is inside
        // a blocked app with the timer counting down), preserve it — clearAll would
        // wipe activeSessionApps and cause the next app event to re-intercept.
        if (!PausaTimerService.isRunning) {
            clearAll()
            PausaLog.d("PausaDebug", "onServiceConnected — clearAll done (no active timer), poller starting")
        } else {
            PausaLog.d("PausaDebug", "onServiceConnected — timer active for ${PausaTimerService.currentPackage}, preserving session state")
        }
        // ── Step 4: recuperar la sesión guardada en disco si el proceso murió con
        //            una sesión en marcha (después de clearAll para no borrarla).
        restorePersistedSession()

        // Sentinel value — guarantees the first poller tick calls handleAppChange for
        // whatever app is currently in foreground, even if it was already there before
        // the service connected (e.g. TikTok open in background when PAUSA was closed).
        lastForegroundPackage = "__reset__"
        needsLongLookup = true
        serviceInfo = AccessibilityServiceInfo().apply {
            eventTypes = AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED or
                    AccessibilityEvent.TYPE_WINDOWS_CHANGED or
                    AccessibilityEvent.TYPE_VIEW_FOCUSED
            feedbackType = AccessibilityServiceInfo.FEEDBACK_GENERIC
            flags = AccessibilityServiceInfo.FLAG_REPORT_VIEW_IDS or
                    AccessibilityServiceInfo.FLAG_INCLUDE_NOT_IMPORTANT_VIEWS
            notificationTimeout = 50
        }
        registerReceiver(screenReceiver, IntentFilter().apply {
            addAction(Intent.ACTION_SCREEN_ON)
            addAction(Intent.ACTION_SCREEN_OFF)
            addAction(Intent.ACTION_USER_PRESENT)
        })
        handler.post(foregroundPoller)

        // Si el sistema revive el servicio sin que se abra la app (tras matar el
        // proceso o reiniciar el móvil), la notificación que protege el proceso
        // tiene que volver también.
        PausaKeepaliveService.start(this)
    }

    private fun restorePersistedSession() {
        val saved = SessionStore.load(this) ?: return
        if (PausaTimerService.isRunning) {
            // El temporizador ya volvió por su cuenta (START_STICKY).
            if (PausaTimerService.currentPackage == saved.packageName) restoreSession(saved.packageName)
            return
        }
        val interactive = (getSystemService(Context.POWER_SERVICE) as android.os.PowerManager).isInteractive
        val front = ForegroundHelper.lastForegroundPackage(this)
        if (!interactive || front != saved.packageName) {
            // No se puede confirmar que la app siga delante: se cierra la sesión
            // sin expulsar, contando el uso solo hasta el último latido.
            PausaLog.d("PausaDebug", "sesión guardada de ${saved.packageName} NO restaurada (delante: $front / pantalla activa: $interactive)")
            SessionStore.end(this, saved.packageName, null)
            return
        }
        PausaLog.d("PausaDebug", "restaurando sesión de ${saved.packageName} (inicio ${saved.startMs}, máx ${saved.maxSeconds}s)")
        restoreSession(saved.packageName)
        try {
            startService(Intent(this, PausaTimerService::class.java).putExtra("restore", true))
        } catch (e: Exception) {
            PausaLog.e("PausaDebug", "no se pudo arrancar el temporizador al restaurar: $e")
        }
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        // Solo usamos el evento para asegurarnos de que el poller está corriendo.
        // NO disparamos handleAppChange aquí — el poller con UsageStats es la única
        // fuente de verdad para detectar cambios de app reales.
        // Esto evita falsos positivos por navegación interna (botón atrás, fragments, etc.)
        if (event?.eventType == AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED) {
            handler.removeCallbacks(foregroundPoller)
            handler.post(foregroundPoller)
        }
    }

    override fun onInterrupt() {
        handler.removeCallbacks(foregroundPoller)
    }

    override fun onUnbind(intent: Intent?): Boolean {
        isConnected = false
        return super.onUnbind(intent)
    }

    override fun onDestroy() {
        super.onDestroy()
        isConnected = false
        handler.removeCallbacks(foregroundPoller)
        handler.removeCallbacks(interstitialWatchdog)
        pendingIntercepts.clear()
        try { unregisterReceiver(screenReceiver) } catch (e: Exception) {}
    }

    // ── Core logic — shared by onAccessibilityEvent and foregroundPoller ─────

    /** Tell the timer service to stop for a package the user voluntarily left. */
    private fun sendStopTimer(pkg: String) {
        if (pkg.isEmpty()) return
        PausaTimerService.stopIfRunning(pkg)
    }

    private fun handleAppChange(packageName: String) {
        PausaLog.d("PausaDebug", "handleAppChange — pkg: $packageName / inSession: ${isInActiveSession(packageName)} / expelled: ${isExpelled(packageName)} / expelling: $isExpelling")

        // Our own app came to foreground — do NOT stop timer here.
        // MainActivity.onResume handles this exclusively via PausaTimerService.stopAll().
        if (packageName == applicationContext.packageName ||
            packageName.startsWith("com.pausa.")) {
            PausaLog.d("PausaDebug", "GUARD pausa-package — skipping $packageName")
            return
        }
        if (packageName.contains("pausa")) {
            PausaLog.d("PausaDebug", "GUARD contains-pausa — skipping $packageName")
            return
        }
        // MIUI system UI (notification shade, status bar animations, etc.)
        if (packageName.contains("miui.systemui") ||
            packageName.contains("miui.system")) {
            PausaLog.d("PausaDebug", "GUARD miui-system — skipping $packageName")
            return
        }

        // Global expulsion guard — ignore all events for 10 seconds after any expulsion
        // to prevent the crash loop caused by our MainActivity coming to foreground
        if (isExpelling) {
            PausaLog.d("PausaDebug", "GUARD isExpelling — skipping $packageName")
            return
        }

        // Home / launcher came to foreground — end active session.
        // If lastForegroundPackage is PAUSA itself (interstitial was showing), use
        // activeTimerPackage (the package that owns the running timer) as the real session.
        // Falls back to activeSessionApps.firstOrNull() when no timer is running (countdown
        // not yet finished), and to lastForegroundPackage as final fallback.
        if (packageName in homeAndLauncherPackages) {
            val sessionToEnd = when {
                lastForegroundPackage == applicationContext.packageName ||
                lastForegroundPackage.startsWith("com.pausa.") -> {
                    // PAUSA was in foreground (interstitial) — use the active timer package
                    PausaTimerService.currentPackage.takeIf { it.isNotEmpty() }
                        ?: activeSessionApps.firstOrNull()
                        ?: lastForegroundPackage
                }
                lastForegroundPackage.isNotEmpty() && lastForegroundPackage != "__reset__" ->
                    lastForegroundPackage
                else ->
                    activeSessionApps.firstOrNull() ?: ""
            }
            PausaLog.d("PausaDebug", "GUARD home-launcher — ending session for $sessionToEnd (last=$lastForegroundPackage)")
            if (sessionToEnd.isNotEmpty() && sessionToEnd in activeSessionApps) {
                sendStopTimer(sessionToEnd)
                endSession(sessionToEnd)
            }
            lastForegroundPackage = "" // ALWAYS reset so next app open is detected fresh
            return
        }

        // Task switcher — transient UI, do NOT end the session.
        // The user may return to the same app; only reset lastForegroundPackage so
        // the next foreground app is detected correctly.
        if (packageName in taskSwitcherPackages) {
            PausaLog.d("PausaDebug", "GUARD task-switcher — resetting last (no session end) for $lastForegroundPackage")
            lastForegroundPackage = ""
            return
        }

        if (packageName in ignoredPackages) {
            PausaLog.d("PausaDebug", "GUARD ignoredPackages — skipping $packageName")
            return
        }
        if (packageName.startsWith("com.android.") &&
            packageName != "com.android.chrome") {
            PausaLog.d("PausaDebug", "GUARD com.android.* — skipping $packageName")
            return
        }

        // Recently expelled — suppress BEFORE active-session check.
        // markExpelled removes from activeSessionApps, but the ordering makes
        // intent explicit and guards against any future state inconsistency.
        if (isExpelled(packageName)) {
            PausaLog.d("PausaDebug", "GUARD isExpelled — suppressing $packageName")
            expelledApps.remove(packageName)
            return
        }

        // In active session — pass through freely
        if (isInActiveSession(packageName)) {
            PausaLog.d("PausaDebug", "GUARD inActiveSession — passing through $packageName")
            return
        }

        // Different app came to foreground — end previous session
        if (lastForegroundPackage != packageName &&
            lastForegroundPackage in activeSessionApps) {
            PausaLog.d("PausaDebug", "ending previous session for $lastForegroundPackage (new app: $packageName)")
            sendStopTimer(lastForegroundPackage)
            endSession(lastForegroundPackage)
        }

        // Check if this app has an active pausa
        val pausaConfig = getPausaForPackage(packageName) ?: run {
            PausaLog.d("PausaDebug", "no pausa config for $packageName — skipping")
            return
        }

        // Queue a pending intercept — the poller fires it once it confirms the app
        // is actually in the foreground. This handles cold-start splash screens (e.g.
        // TikTok) where the accessibility event fires during the splash activity but
        // UsageStats won't report the app as foreground until the main activity loads.
        if (pendingIntercepts.containsKey(packageName)) {
            PausaLog.d("PausaDebug", "PENDING intercept already queued for $packageName — skipping")
            return
        }
        val deadline = System.currentTimeMillis() + 3000L
        pendingIntercepts[packageName] = deadline
        PausaLog.d("PausaDebug", "PENDING intercept queued for $packageName (deadline in 3s)")
    }

    // ── UsageStats poller ─────────────────────────────────────────────────────

    /**
     * App en primer plano para este tic. Normalmente la ventana corta; justo
     * después de conectar, la búsqueda larga (último evento de primer plano).
     */
    private fun resolveForegroundApp(): String? {
        val now = System.currentTimeMillis()
        if (needsLongLookup) {
            needsLongLookup = false
            val pkg = ForegroundHelper.lastForegroundPackage(this)
            PausaLog.d("PausaDebug", "búsqueda larga tras conectar — app delante: $pkg")
            if (pkg != null) {
                stickyForeground = pkg
                stickyUntilMs = now + 4000L
            }
            return pkg
        }
        val recent = getCurrentForegroundApp()
        if (recent != null) {
            stickyForeground = null
            return recent
        }
        return stickyForeground?.takeIf { now <= stickyUntilMs }
    }

    private fun getCurrentForegroundApp(): String? {
        return try {
            val usm = getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
            val now = System.currentTimeMillis()
            val events = usm.queryEvents(now - 2000, now)
            val event = UsageEvents.Event()
            var last = ""
            while (events.hasNextEvent()) {
                events.getNextEvent(event)
                if (event.eventType == UsageEvents.Event.MOVE_TO_FOREGROUND) {
                    last = event.packageName
                }
            }
            last.ifEmpty { null }
        } catch (e: Exception) { null }
    }

    // ── SharedPreferences lookup ──────────────────────────────────────────────

    private fun getPausaForPackage(packageName: String): Triple<String, Int, Int>? {
        val prefs = applicationContext.getSharedPreferences(
            "pausa_prefs", Context.MODE_PRIVATE
        )
        val json = prefs.getString("pausas_list", "[]") ?: return null
        return try {
            val array = org.json.JSONArray(json)
            for (i in 0 until array.length()) {
                val obj = array.getJSONObject(i)
                if (obj.getString("packageName") == packageName &&
                    obj.getBoolean("isActive")) {
                    return Triple(
                        obj.getString("appName"),
                        obj.getInt("waitSeconds"),
                        obj.getInt("maxMinutes")
                    )
                }
            }
            null
        } catch (e: Exception) { null }
    }
}
