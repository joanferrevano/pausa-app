package com.pausa.pausa_app

import android.app.*
import android.content.Context
import android.content.Intent
import android.os.*
import android.util.Log
import androidx.core.app.NotificationCompat

class PausaTimerService : Service() {

    val handler: Handler = Handler(Looper.getMainLooper())
    private var packageName: String = ""
    private var appName: String = ""
    private var maxSeconds: Int = 0
    private var isStopping = false
    private var startTimeMs: Long = 0L
    // true si la sesión se recuperó del disco tras morir el proceso: no sabemos
    // con certeza qué pasó mientras tanto, así que solo se expulsa si se puede
    // confirmar que la app está realmente delante con la pantalla activa.
    private var restored = false

    val timerRunnable: Runnable = object : Runnable {
        override fun run() {
            // Cambio de día con la sesión abierta: el contador diario empieza de
            // cero, así que la sesión sigue desde las 00:00 con el máximo de hoy.
            if (!SessionStore.isSameDay(startTimeMs, System.currentTimeMillis()) && !rollOverToNewDay()) {
                return
            }
            val elapsed = elapsedSeconds()
            val remaining = maxSeconds - elapsed

            Log.d("PausaTimer", "tick — elapsed: ${elapsed}s / max: ${maxSeconds}s / pkg: $packageName")

            if (elapsed % 10 == 0) {
                SessionStore.heartbeat(this@PausaTimerService)
                val nm = getSystemService(NOTIFICATION_SERVICE) as NotificationManager
                nm.notify(NOTIFICATION_ID, buildNotification(remaining.coerceAtLeast(0)))
            }

            if (elapsed >= maxSeconds) {
                handler.removeCallbacks(this)
                Log.d("PausaTimer", "TIME UP for $packageName")
                // Solo se expulsa con confirmación positiva: pantalla activa y la app
                // delante. Ante la duda (pantalla apagada, sin eventos, error) no se
                // expulsa: un falso positivo bloquea la app hasta medianoche.
                if (isConfirmedInForeground()) {
                    Log.d("PausaTimer", "App still in foreground — expelling")
                    expelUser()
                } else {
                    Log.d("PausaTimer", "App not in foreground — stopping silently")
                    PausaAccessibilityService.endSession(packageName)
                    stopSelf()
                }
                return
            }

            handler.postDelayed(this, 1000)
        }
    }

    companion object {
        const val CHANNEL_ID = "pausa_timer_channel"
        const val NOTIFICATION_ID = 1001
        // Margen sobre el inicio de la sesión al buscar la app delante: la cuenta
        // atrás y la entrada en la app ocurren unos segundos alrededor del inicio.
        private const val WINDOW_MARGIN_MS = 5 * 60 * 1000L

        // Los campos estáticos NO sobreviven a que el sistema mate el proceso:
        // la sesión se guarda en disco con SessionStore y se restaura de ahí.

        // Singleton access for direct static calls (no broadcast needed)
        private var instance: PausaTimerService? = null

        var isRunning = false
            private set
        var currentPackage = ""
            private set

        /** Stop timer for a specific package — called by AccessibilityService on voluntary exit. */
        fun stopIfRunning(pkg: String) {
            val inst = instance ?: return
            if (inst.isStopping) return // already in teardown
            if (inst.packageName.isNotEmpty() && inst.packageName != pkg) return
            Log.d("PausaTimer", "stopIfRunning: stopping timer for $pkg")
            inst.isStopping = true
            inst.handler.removeCallbacks(inst.timerRunnable)
            inst.stopSelf()
        }

        /** Stop all timers — called by MainActivity.onResume when PAUSA opens. */
        fun stopAll() {
            val inst = instance ?: return
            if (inst.isStopping) return // already in teardown
            Log.d("PausaTimer", "stopAll: stopping timer for ${inst.packageName}")
            inst.isStopping = true
            inst.handler.removeCallbacks(inst.timerRunnable)
            // Post stopSelf to avoid calling it from an external thread context
            inst.handler.post { inst.stopSelf() }
        }
    }

    override fun onCreate() {
        super.onCreate()
        instance = this
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        if (intent != null && !intent.getBooleanExtra("restore", false)) {
            val newPackage = intent.getStringExtra("packageName") ?: return START_NOT_STICKY

            // Already running for same package — ignore duplicate start
            if (isRunning && currentPackage == newPackage) {
                Log.d("PausaTimer", "Already running for $newPackage — ignoring duplicate start")
                return START_NOT_STICKY
            }

            // Running for different package — stop the previous timer cleanly
            if (isRunning && currentPackage != newPackage) {
                Log.d("PausaTimer", "Switching timer from $currentPackage to $newPackage")
                handler.removeCallbacks(timerRunnable)
                PausaAccessibilityService.endSession(currentPackage)
                SessionStore.end(this, currentPackage, System.currentTimeMillis())
            }

            // Límite diario acumulado: la sesión dura lo que queda de hoy, no el
            // máximo entero.
            val remainingToday = SessionStore.remainingSecondsToday(
                this, newPackage, intent.getIntExtra("maxMinutes", 20)
            )
            if (remainingToday <= 0) {
                // No debería llegar aquí (el bloqueo diario corta antes), pero si
                // llega no hay sesión que dar: el poller mandará la app al inicio.
                Log.d("PausaTimer", "sin tiempo restante hoy para $newPackage — no se inicia sesión")
                PausaAccessibilityService.endSession(newPackage)
                packageName = ""
                isRunning = false
                currentPackage = ""
                stopSelf()
                return START_NOT_STICKY
            }

            packageName = newPackage
            appName = intent.getStringExtra("appName") ?: newPackage
            maxSeconds = remainingToday
            startTimeMs = System.currentTimeMillis()
            restored = false
            SessionStore.start(this, packageName, appName, startTimeMs, maxSeconds)
            isRunning = true
            currentPackage = packageName
            Log.d("PausaTimer", "started — pkg: $packageName / maxSeconds: $maxSeconds")
        } else {
            // Reinicio tras morir el proceso (intent nulo de START_STICKY, o petición
            // de restauración del servicio de accesibilidad): recuperar del disco.
            val saved = SessionStore.load(this)
            if (saved == null) {
                if (!isRunning) stopSelf()
                return START_NOT_STICKY
            }
            if (isRunning && currentPackage == saved.packageName) {
                Log.d("PausaTimer", "restore — ya en marcha para ${saved.packageName}")
                return START_STICKY
            }
            packageName = saved.packageName
            appName = saved.appName
            maxSeconds = saved.maxSeconds
            startTimeMs = saved.startMs
            restored = true
            isRunning = true
            currentPackage = packageName
            PausaAccessibilityService.restoreSession(packageName)
            Log.d("PausaTimer", "restaurada del disco — pkg: $packageName / elapsed: ${elapsedSeconds()}s / max: ${maxSeconds}s")
        }

        createNotificationChannel()
        val initialRemaining = (maxSeconds - elapsedSeconds()).coerceAtLeast(0)
        try {
            // specialUse solo existe desde Android 14; antes el tipo no hace falta.
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
                startForeground(
                    NOTIFICATION_ID,
                    buildNotification(initialRemaining),
                    android.content.pm.ServiceInfo.FOREGROUND_SERVICE_TYPE_SPECIAL_USE
                )
            } else {
                startForeground(NOTIFICATION_ID, buildNotification(initialRemaining))
            }
        } catch (e: Exception) {
            // Al restaurar desde segundo plano Android puede negar el primer plano.
            // El temporizador sigue igualmente: el proceso lo mantienen vivo el
            // servicio de accesibilidad y el keepalive.
            Log.e("PausaTimer", "startForeground falló (restored=$restored): $e")
        }

        handler.removeCallbacks(timerRunnable)
        handler.post(timerRunnable)

        return START_STICKY
    }

    /** Wall-clock elapsed seconds — accurate across kill/restart cycles. */
    private fun elapsedSeconds(): Int {
        val start = startTimeMs
        if (start == 0L) return 0
        return ((System.currentTimeMillis() - start) / 1000).toInt()
    }

    /**
     * La sesión ha cruzado la medianoche. Cierra la de ayer y la reabre desde
     * las 00:00 con el máximo de hoy. Devuelve false si ya no hay nada que
     * cronometrar (pausa borrada, desactivada o sin límite) y el servicio se para.
     */
    private fun rollOverToNewDay(): Boolean {
        val now = System.currentTimeMillis()
        SessionStore.end(this, packageName, now)
        val maxMinutes = SessionStore.configuredMaxMinutes(this, packageName) ?: 0
        val remaining = if (maxMinutes > 0) {
            SessionStore.remainingSecondsToday(this, packageName, maxMinutes)
        } else 0
        if (remaining <= 0) {
            Log.d("PausaTimer", "cambio de día — sin límite que aplicar a $packageName, se para")
            handler.removeCallbacks(timerRunnable)
            stopSelf()
            return false
        }
        startTimeMs = SessionStore.startOfDay(now)
        maxSeconds = remaining
        SessionStore.start(this, packageName, appName, startTimeMs, maxSeconds)
        SessionStore.heartbeat(this, now)
        Log.d("PausaTimer", "cambio de día — sesión de $packageName reabierta con ${maxSeconds}s")
        return true
    }

    private fun expelUser() {
        Log.d("PausaTimer", "expelUser called for $packageName")
        // Sumar el uso ya: el bloqueo diario se calcula con el acumulado y tiene
        // que estar al día antes de que el usuario intente volver a entrar.
        SessionStore.end(this, packageName, System.currentTimeMillis())
        PausaAccessibilityService.markExpelled(packageName)

        // ── Expulsion notification ────────────────────────────────────────────
        val expulsionChannelId = "pausa_expulsion"
        val nm = getSystemService(NOTIFICATION_SERVICE) as NotificationManager
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                expulsionChannelId,
                "Pausa",
                NotificationManager.IMPORTANCE_DEFAULT
            )
            nm.createNotificationChannel(channel)
        }
        val displayName = try {
            packageManager.getApplicationLabel(
                packageManager.getApplicationInfo(packageName, 0)
            ).toString()
        } catch (e: Exception) { appName }
        val expulsionNotification = NotificationCompat.Builder(this, expulsionChannelId)
            .setSmallIcon(android.R.drawable.ic_lock_idle_lock)
            .setContentTitle("Tiempo agotado")
            .setContentText("Has agotado tu tiempo de $displayName por hoy. Vuelve mañana.")
            .setAutoCancel(true)
            .build()
        nm.notify(packageName.hashCode(), expulsionNotification)
        Log.d("PausaTimer", "expulsion notification shown for $displayName")
        // ─────────────────────────────────────────────────────────────────────

        val baseHomeIntent = Intent(Intent.ACTION_MAIN).apply {
            addCategory(Intent.CATEGORY_HOME)
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP)
        }
        val resolvedLauncher = applicationContext.packageManager
            .resolveActivity(baseHomeIntent, 0)
        val homeIntent = if (resolvedLauncher != null) {
            Intent(Intent.ACTION_MAIN).apply {
                addCategory(Intent.CATEGORY_HOME)
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP)
                setPackage(resolvedLauncher.activityInfo.packageName)
            }
        } else {
            baseHomeIntent
        }
        Log.d("PausaTimer", "going home via: ${resolvedLauncher?.activityInfo?.packageName ?: "generic"}")
        startActivity(homeIntent)

        // Stay alive for 10 s so the AccessibilityService isExpelling window has time to settle
        handler.postDelayed({ stopSelf() }, 10000)
    }

    private fun buildNotification(remainingSeconds: Int): Notification {
        val minutes = remainingSeconds / 60
        val seconds = remainingSeconds % 60
        val timeText = if (minutes > 0) "${minutes}m ${seconds}s" else "${seconds}s"
        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("⏱ $appName — quedan $timeText hoy")
            .setContentText("PAUSA activo")
            .setSmallIcon(android.R.drawable.ic_lock_idle_alarm)
            .setOngoing(true)
            .setSilent(true)
            .setPriority(NotificationCompat.PRIORITY_MIN)
            .setVisibility(NotificationCompat.VISIBILITY_SECRET)
            .setShowWhen(false)
            .build()
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID, "Pausa Timer",
                NotificationManager.IMPORTANCE_MIN
            ).apply {
                description = "Tiempo restante en apps pausadas"
                setShowBadge(false)
                setSound(null, null)
                enableLights(false)
                enableVibration(false)
            }
            getSystemService(NotificationManager::class.java)
                .createNotificationChannel(channel)
        }
    }

    override fun onBind(intent: Intent?): IBinder? = null

    /**
     * Comprobación estricta antes de expulsar: pantalla activa y el último
     * evento de primer plano es de esta app y sigue delante.
     *
     * La ventana cubre siempre la sesión entera: quien se queda en una sola
     * pantalla (un vídeo, sin tocar nada) no genera eventos nuevos, y el único
     * que lo delata es el de cuando entró, justo al empezar la sesión.
     */
    private fun isConfirmedInForeground(): Boolean {
        val pm = getSystemService(Context.POWER_SERVICE) as PowerManager
        if (!pm.isInteractive) {
            Log.d("PausaTimer", "pantalla apagada — no se expulsa")
            return false
        }
        val sinceStart = System.currentTimeMillis() - startTimeMs + WINDOW_MARGIN_MS
        val window = maxOf(ForegroundHelper.LONG_WINDOW_MS, sinceStart)
        val front = ForegroundHelper.lastForegroundPackage(this, window)
        Log.d("PausaTimer", "app delante al agotarse el tiempo: $front")
        return front == packageName
    }

    override fun onDestroy() {
        super.onDestroy()
        Log.d("PausaTimer", "onDestroy for $packageName")
        handler.removeCallbacks(timerRunnable)
        if (packageName.isNotEmpty()) {
            // Sesión restaurada: contar solo hasta el último latido conocido.
            SessionStore.end(this, packageName, if (restored) null else System.currentTimeMillis())
        }
        PausaAccessibilityService.endSession(packageName)
        instance = null
        isRunning = false
        currentPackage = ""
        isStopping = false // reset for next instance
    }
}
