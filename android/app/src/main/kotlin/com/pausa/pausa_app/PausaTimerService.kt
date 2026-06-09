package com.pausa.pausa_app

import android.app.*
import android.app.usage.UsageEvents
import android.app.usage.UsageStatsManager
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

    val timerRunnable: Runnable = object : Runnable {
        override fun run() {
            val elapsed = elapsedSeconds()
            val remaining = maxSeconds - elapsed

            Log.d("PausaTimer", "tick — elapsed: ${elapsed}s / max: ${maxSeconds}s / pkg: $packageName")

            if (elapsed % 10 == 0) {
                val nm = getSystemService(NOTIFICATION_SERVICE) as NotificationManager
                nm.notify(NOTIFICATION_ID, buildNotification(remaining.coerceAtLeast(0)))
            }

            if (elapsed >= maxSeconds) {
                handler.removeCallbacks(this)
                Log.d("PausaTimer", "TIME UP for $packageName")
                if (isBlockedAppInForeground()) {
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

        // Static fields survive process kill + START_STICKY restart
        private var savedPackageName = ""
        private var savedAppName = ""
        private var savedMaxSeconds = 0
        private var savedStartTimeMs = 0L

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
        if (intent != null) {
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
            }

            packageName = newPackage
            appName = intent.getStringExtra("appName") ?: newPackage
            maxSeconds = intent.getIntExtra("maxMinutes", 20) * 60
            savedPackageName = packageName
            savedAppName = appName
            savedMaxSeconds = maxSeconds
            savedStartTimeMs = System.currentTimeMillis()
            isRunning = true
            currentPackage = packageName
            Log.d("PausaTimer", "started — pkg: $packageName / maxSeconds: $maxSeconds")
        } else {
            // Android restarted the service after kill — restore from static fields
            packageName = savedPackageName
            appName = savedAppName
            maxSeconds = savedMaxSeconds
            if (packageName.isEmpty()) {
                stopSelf()
                return START_NOT_STICKY
            }
            isRunning = true
            currentPackage = packageName
            Log.d("PausaTimer", "restarted by Android — pkg: $packageName / elapsed: ${elapsedSeconds()}s")
        }

        createNotificationChannel()
        val initialRemaining = (maxSeconds - elapsedSeconds()).coerceAtLeast(0)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            startForeground(
                NOTIFICATION_ID,
                buildNotification(initialRemaining),
                android.content.pm.ServiceInfo.FOREGROUND_SERVICE_TYPE_MEDIA_PLAYBACK
            )
        } else {
            startForeground(NOTIFICATION_ID, buildNotification(initialRemaining))
        }

        handler.removeCallbacks(timerRunnable)
        handler.post(timerRunnable)

        return START_STICKY
    }

    /** Wall-clock elapsed seconds — accurate across kill/restart cycles. */
    private fun elapsedSeconds(): Int {
        val start = savedStartTimeMs
        if (start == 0L) return 0
        return ((System.currentTimeMillis() - start) / 1000).toInt()
    }

    private fun expelUser() {
        Log.d("PausaTimer", "expelUser called for $packageName")
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
            .setContentText("Has usado $displayName por hoy. Vuelve mañana.")
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
            .setContentTitle("⏱ $appName — $timeText")
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

    private fun isBlockedAppInForeground(): Boolean {
        return try {
            val usm = getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
            val now = System.currentTimeMillis()
            val events = usm.queryEvents(now - 5000, now)
            val event = UsageEvents.Event()
            var lastFg = ""
            var lastBg = ""
            while (events.hasNextEvent()) {
                events.getNextEvent(event)
                when (event.eventType) {
                    UsageEvents.Event.MOVE_TO_FOREGROUND -> lastFg = event.packageName
                    UsageEvents.Event.MOVE_TO_BACKGROUND -> lastBg = event.packageName
                }
            }
            if (lastBg == packageName && lastFg != packageName) return false
            if (lastFg.isNotEmpty()) return lastFg == packageName
            true
        } catch (e: Exception) {
            true
        }
    }

    override fun onDestroy() {
        super.onDestroy()
        Log.d("PausaTimer", "onDestroy for $packageName")
        handler.removeCallbacks(timerRunnable)
        PausaAccessibilityService.endSession(packageName)
        instance = null
        isRunning = false
        currentPackage = ""
        isStopping = false // reset for next instance
    }
}
