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
import android.util.Log
import android.view.accessibility.AccessibilityEvent

class PausaAccessibilityService : AccessibilityService() {

    private var lastForegroundPackage = ""
    private val handler = Handler(Looper.getMainLooper())

    private val screenOnReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context?, intent: Intent?) {
            if (intent?.action == Intent.ACTION_SCREEN_ON) {
                Log.d("PausaDebug", "pantalla encendida — reiniciando poller")
                // Sentinel forces the next poller tick to evaluate whatever app is in
                // foreground, even if it was already there before the screen turned off.
                // If the timer expired while the screen was off, the app will have no
                // active session and pendingIntercepts will re-trigger the countdown.
                lastForegroundPackage = "__reset__"
                handler.removeCallbacks(foregroundPoller)
                handler.postDelayed(foregroundPoller, 500)
            }
        }
    }

    // Polls UsageStats every second as a backup — catches resumptions that
    // don't fire a strong enough AccessibilityEvent (e.g. task resume).
    private val foregroundPoller = object : Runnable {
        override fun run() {
            val current = getCurrentForegroundApp() ?: run {
                handler.postDelayed(this, 1000)
                return
            }
            Log.d("PausaDebug", "poller — current: $current / last: $lastForegroundPackage / isExpelling: $isExpelling / pending: ${pendingIntercepts.keys}")

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

            // Process pending intercepts — fire when the target app is confirmed foreground
            val now = System.currentTimeMillis()
            val iter = pendingIntercepts.iterator()
            while (iter.hasNext()) {
                val (pkg, deadline) = iter.next()
                if (now > deadline) {
                    Log.d("PausaDebug", "PENDING intercept expired for $pkg")
                    iter.remove()
                    continue
                }
                if (current == pkg) {
                    iter.remove()
                    Log.d("PausaDebug", "PENDING intercept for $pkg — wasRecentlyExpelled: ${wasRecentlyExpelled(pkg)} / isInDailyCooldown: ${isInDailyCooldown(pkg)}")
                    if (wasRecentlyExpelled(pkg) || isInDailyCooldown(pkg)) {
                        // Still in expulsion/cooldown window — send straight home
                        Log.d("PausaDebug", "PENDING intercept blocked — daily cooldown active for $pkg")
                        startActivity(Intent(Intent.ACTION_MAIN).apply {
                            addCategory(Intent.CATEGORY_HOME)
                            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                        })
                    } else if (!isInActiveSession(pkg) && !isExpelled(pkg) && !isExpelling) {
                        val pausaConfig = getPausaForPackage(pkg) ?: continue
                        Log.d("PausaDebug", "PENDING intercept firing for $pkg")
                        lastForegroundPackage = pkg
                        startActivity(Intent(this@PausaAccessibilityService,
                            PausaInterstitialActivity::class.java).apply {
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

        fun endSession(packageName: String) {
            activeSessionApps.remove(packageName)
            expelledApps.remove(packageName)
            if (activeTimerPackage == packageName) activeTimerPackage = ""
        }

        fun markExpelled(packageName: String) {
            isExpelling = true
            lastExpelledPackage = packageName
            lastExpelledTimeMs = System.currentTimeMillis()
            Log.d("PausaDebug", "markExpelled called for $packageName — setting lastExpelledTimeMs=$lastExpelledTimeMs")
            // Persist so it survives process restart (MIUI kills and restarts the process)
            if (appContext == null) {
                Log.e("PausaDebug", "markExpelled — appContext is NULL, cannot persist expelled state!")
            } else {
                val today = java.text.SimpleDateFormat("yyyyMMdd", java.util.Locale.getDefault())
                    .format(java.util.Date())
                appContext!!.getSharedPreferences("pausa_prefs", Context.MODE_PRIVATE)
                    .edit()
                    .putString("last_expelled_pkg", packageName)
                    .putLong("last_expelled_ms", lastExpelledTimeMs)
                    .putString("expelled_day_$packageName", today)
                    .apply()
                Log.d("PausaDebug", "markExpelled — persisted to prefs OK, stored expulsion day: $today for $packageName")
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
            Log.d("PausaDebug", "wasRecentlyExpelled($packageName) — savedPkg=$savedPkg savedMs=$savedMs diff=${diff}ms result=$result")
            return result
        }

        fun resetDailyCooldown(packageName: String) {
            appContext?.getSharedPreferences("pausa_prefs", Context.MODE_PRIVATE)
                ?.edit()
                ?.remove("expelled_day_$packageName")
                ?.apply()
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
            Log.d("PausaDebug", "resetDailyCooldown — cooldown cleared for $packageName")
        }

        fun isInDailyCooldown(packageName: String): Boolean {
            val prefs = appContext?.getSharedPreferences("pausa_prefs", Context.MODE_PRIVATE)
                ?: return false
            val expelledDay = prefs.getString("expelled_day_$packageName", "") ?: ""
            if (expelledDay.isEmpty()) return false
            val today = java.text.SimpleDateFormat("yyyyMMdd", java.util.Locale.getDefault())
                .format(java.util.Date())
            val result = expelledDay == today
            Log.d("PausaDebug", "isInDailyCooldown($packageName) — expelledDay=$expelledDay today=$today result=$result")
            return result
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
            Log.d("PausaDebug", "clearAll — preserving expelled prefs: pkg=$preservedPkg ms=$preservedMs")
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

        // ── Step 2: restore expelled state from prefs BEFORE clearAll() so the
        //            in-memory values are populated when clearAll's log reads them.
        //            MIUI kills and restarts the process after expulsion, resetting
        //            all companion-object vars to their default values.
        val prefs = getSharedPreferences("pausa_prefs", Context.MODE_PRIVATE)
        lastExpelledPackage = prefs.getString("last_expelled_pkg", "") ?: ""
        lastExpelledTimeMs = prefs.getLong("last_expelled_ms", 0L)
        val today = java.text.SimpleDateFormat("yyyyMMdd", java.util.Locale.getDefault())
            .format(java.util.Date())
        Log.d("PausaDebug", "onServiceConnected — today=$today restored lastExpelledPkg=$lastExpelledPackage lastExpelledMs=$lastExpelledTimeMs")

        // ── Step 3: clear session state (but NOT expelled prefs — see clearAll()).
        // Only clear state if no timer is running. If a session is active (user is inside
        // a blocked app with the timer counting down), preserve it — clearAll would
        // wipe activeSessionApps and cause the next app event to re-intercept.
        if (!PausaTimerService.isRunning) {
            clearAll()
            Log.d("PausaDebug", "onServiceConnected — clearAll done (no active timer), poller starting")
        } else {
            Log.d("PausaDebug", "onServiceConnected — timer active for ${PausaTimerService.currentPackage}, preserving session state")
        }
        // Sentinel value — guarantees the first poller tick calls handleAppChange for
        // whatever app is currently in foreground, even if it was already there before
        // the service connected (e.g. TikTok open in background when PAUSA was closed).
        lastForegroundPackage = "__reset__"
        serviceInfo = AccessibilityServiceInfo().apply {
            eventTypes = AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED or
                    AccessibilityEvent.TYPE_WINDOWS_CHANGED or
                    AccessibilityEvent.TYPE_VIEW_FOCUSED
            feedbackType = AccessibilityServiceInfo.FEEDBACK_GENERIC
            flags = AccessibilityServiceInfo.FLAG_REPORT_VIEW_IDS or
                    AccessibilityServiceInfo.FLAG_INCLUDE_NOT_IMPORTANT_VIEWS
            notificationTimeout = 50
        }
        registerReceiver(screenOnReceiver, IntentFilter(Intent.ACTION_SCREEN_ON))
        handler.post(foregroundPoller)
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

    override fun onDestroy() {
        super.onDestroy()
        handler.removeCallbacks(foregroundPoller)
        pendingIntercepts.clear()
        try { unregisterReceiver(screenOnReceiver) } catch (e: Exception) {}
    }

    // ── Core logic — shared by onAccessibilityEvent and foregroundPoller ─────

    /** Tell the timer service to stop for a package the user voluntarily left. */
    private fun sendStopTimer(pkg: String) {
        if (pkg.isEmpty()) return
        PausaTimerService.stopIfRunning(pkg)
    }

    private fun handleAppChange(packageName: String) {
        Log.d("PausaDebug", "handleAppChange — pkg: $packageName / inSession: ${isInActiveSession(packageName)} / expelled: ${isExpelled(packageName)} / expelling: $isExpelling")

        // Our own app came to foreground — do NOT stop timer here.
        // MainActivity.onResume handles this exclusively via PausaTimerService.stopAll().
        if (packageName == applicationContext.packageName ||
            packageName.startsWith("com.pausa.")) {
            Log.d("PausaDebug", "GUARD pausa-package — skipping $packageName")
            return
        }
        if (packageName.contains("pausa")) {
            Log.d("PausaDebug", "GUARD contains-pausa — skipping $packageName")
            return
        }
        // MIUI system UI (notification shade, status bar animations, etc.)
        if (packageName.contains("miui.systemui") ||
            packageName.contains("miui.system")) {
            Log.d("PausaDebug", "GUARD miui-system — skipping $packageName")
            return
        }

        // Global expulsion guard — ignore all events for 10 seconds after any expulsion
        // to prevent the crash loop caused by our MainActivity coming to foreground
        if (isExpelling) {
            Log.d("PausaDebug", "GUARD isExpelling — skipping $packageName")
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
            Log.d("PausaDebug", "GUARD home-launcher — ending session for $sessionToEnd (last=$lastForegroundPackage)")
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
            Log.d("PausaDebug", "GUARD task-switcher — resetting last (no session end) for $lastForegroundPackage")
            lastForegroundPackage = ""
            return
        }

        if (packageName in ignoredPackages) {
            Log.d("PausaDebug", "GUARD ignoredPackages — skipping $packageName")
            return
        }
        if (packageName.startsWith("com.android.") &&
            packageName != "com.android.chrome") {
            Log.d("PausaDebug", "GUARD com.android.* — skipping $packageName")
            return
        }

        // Recently expelled — suppress BEFORE active-session check.
        // markExpelled removes from activeSessionApps, but the ordering makes
        // intent explicit and guards against any future state inconsistency.
        if (isExpelled(packageName)) {
            Log.d("PausaDebug", "GUARD isExpelled — suppressing $packageName")
            expelledApps.remove(packageName)
            return
        }

        // In active session — pass through freely
        if (isInActiveSession(packageName)) {
            Log.d("PausaDebug", "GUARD inActiveSession — passing through $packageName")
            return
        }

        // Different app came to foreground — end previous session
        if (lastForegroundPackage != packageName &&
            lastForegroundPackage in activeSessionApps) {
            Log.d("PausaDebug", "ending previous session for $lastForegroundPackage (new app: $packageName)")
            sendStopTimer(lastForegroundPackage)
            endSession(lastForegroundPackage)
        }

        // Check if this app has an active pausa
        val pausaConfig = getPausaForPackage(packageName) ?: run {
            Log.d("PausaDebug", "no pausa config for $packageName — skipping")
            return
        }

        // Queue a pending intercept — the poller fires it once it confirms the app
        // is actually in the foreground. This handles cold-start splash screens (e.g.
        // TikTok) where the accessibility event fires during the splash activity but
        // UsageStats won't report the app as foreground until the main activity loads.
        if (pendingIntercepts.containsKey(packageName)) {
            Log.d("PausaDebug", "PENDING intercept already queued for $packageName — skipping")
            return
        }
        val deadline = System.currentTimeMillis() + 3000L
        pendingIntercepts[packageName] = deadline
        Log.d("PausaDebug", "PENDING intercept queued for $packageName (deadline in 3s)")
    }

    // ── UsageStats poller ─────────────────────────────────────────────────────

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
