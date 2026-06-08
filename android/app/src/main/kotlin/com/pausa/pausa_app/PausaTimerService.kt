package com.pausa.pausa_app

import android.app.*
import android.app.usage.UsageEvents
import android.app.usage.UsageStatsManager
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.graphics.Color
import android.os.*
import android.util.Log
import androidx.core.app.NotificationCompat

class PausaTimerService : Service() {

    private val handler: Handler = Handler(Looper.getMainLooper())
    private var packageName: String = ""
    private var appName: String = ""
    private var maxSeconds: Int = 0

    // Stops all timers when PAUSA app opens (MainActivity.onResume).
    private val stopAllReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context?, intent: Intent?) {
            Log.d("PausaTimer", "STOP_ALL — PAUSA opened, stopping timer for $packageName")
            handler.removeCallbacks(timerRunnable)
            PausaAccessibilityService.endSession(packageName)
            stopSelf()
        }
    }

    // Stops the timer when the AccessibilityService detects the user left voluntarily.
    private val stopReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context?, intent: Intent?) {
            val pkg = intent?.getStringExtra("packageName") ?: return
            if (pkg == packageName) {
                Log.d("PausaTimer", "stop broadcast received for $pkg — user exited voluntarily")
                handler.removeCallbacks(timerRunnable)
                PausaAccessibilityService.endSession(packageName)
                stopSelf()
            }
        }
    }

    private val timerRunnable: Runnable = object : Runnable {
        override fun run() {
            val elapsed = elapsedSeconds()
            val remaining = maxSeconds - elapsed

            Log.d("PausaTimer", "tick — elapsed: ${elapsed}s / max: ${maxSeconds}s / remaining: ${remaining}s / pkg: $packageName")

            if (elapsed % 10 == 0) {
                val nm = getSystemService(NOTIFICATION_SERVICE) as NotificationManager
                nm.notify(NOTIFICATION_ID, buildNotification(remaining.coerceAtLeast(0)))
            }

            if (elapsed >= maxSeconds) {
                handler.removeCallbacks(timerRunnable)
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
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        if (intent != null) {
            // Fresh start — read params from intent and persist to static fields
            packageName = intent.getStringExtra("packageName") ?: return START_NOT_STICKY
            appName = intent.getStringExtra("appName") ?: packageName
            maxSeconds = intent.getIntExtra("maxMinutes", 20) * 60
            savedPackageName = packageName
            savedAppName = appName
            savedMaxSeconds = maxSeconds
            savedStartTimeMs = System.currentTimeMillis()
            Log.d("PausaTimer", "started — pkg: $packageName / maxSeconds: $maxSeconds")
        } else {
            // Android restarted after kill — restore from static fields
            packageName = savedPackageName
            appName = savedAppName
            maxSeconds = savedMaxSeconds
            // Keep savedStartTimeMs as-is — wall clock continues from original start
            if (packageName.isEmpty()) {
                stopSelf()
                return START_NOT_STICKY
            }
            Log.d("PausaTimer", "restarted by Android — pkg: $packageName / elapsed so far: ${elapsedSeconds()}s")
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

        // Register broadcast receivers
        try { unregisterReceiver(stopReceiver) } catch (_: Exception) {}
        try { unregisterReceiver(stopAllReceiver) } catch (_: Exception) {}
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            registerReceiver(stopReceiver, IntentFilter("com.pausa.STOP_TIMER"), RECEIVER_NOT_EXPORTED)
            registerReceiver(stopAllReceiver, IntentFilter("com.pausa.STOP_ALL_TIMERS"), RECEIVER_NOT_EXPORTED)
        } else {
            registerReceiver(stopReceiver, IntentFilter("com.pausa.STOP_TIMER"))
            registerReceiver(stopAllReceiver, IntentFilter("com.pausa.STOP_ALL_TIMERS"))
        }

        // Cancel any existing runnable before starting fresh
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

        // Resolve the actual launcher package so MIUI doesn't redirect to our
        // MainActivity instead of the home screen when fired from a service.
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

        // Stay alive for 10 s so the AccessibilityService isExpelling window has
        // time to suppress all the transition events before the process settles.
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
            true // no events in last 5 s — app is idle but still open
        } catch (e: Exception) {
            true // assume foreground if check fails — better to expel than not
        }
    }

    override fun onDestroy() {
        super.onDestroy()
        try { unregisterReceiver(stopReceiver) } catch (_: Exception) {}
        try { unregisterReceiver(stopAllReceiver) } catch (_: Exception) {}
        handler.removeCallbacks(timerRunnable)
        PausaAccessibilityService.endSession(packageName)
    }
}
