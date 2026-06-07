package com.pausa.pausa_app

import android.app.*
import android.app.usage.UsageEvents
import android.app.usage.UsageStatsManager
import android.content.Context
import android.content.Intent
import android.graphics.Color
import android.os.*
import androidx.core.app.NotificationCompat
import java.util.Timer
import java.util.TimerTask

class PausaTimerService : Service() {

    private var timer: Timer? = null
    private var packageName = ""
    private var appName = ""
    private var maxSeconds = 0
    private var elapsedSeconds = 0

    companion object {
        const val CHANNEL_ID = "pausa_timer_channel"
        const val NOTIFICATION_ID = 1001
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        packageName = intent?.getStringExtra("packageName") ?: return START_NOT_STICKY
        appName = intent.getStringExtra("appName") ?: packageName
        maxSeconds = intent.getIntExtra("maxMinutes", 20) * 60
        elapsedSeconds = 0

        createNotificationChannel()
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            startForeground(
                NOTIFICATION_ID,
                buildNotification(maxSeconds),
                android.content.pm.ServiceInfo.FOREGROUND_SERVICE_TYPE_MEDIA_PLAYBACK
            )
        } else {
            startForeground(NOTIFICATION_ID, buildNotification(maxSeconds))
        }

        timer = Timer()
        timer?.scheduleAtFixedRate(object : TimerTask() {
            private var backgroundCheckCount = 0

            override fun run() {
                val inForeground = isAppInForeground(packageName)

                if (!inForeground) {
                    backgroundCheckCount++
                    // Require 3 consecutive background readings (3 s) before stopping.
                    // Avoids false positives during internal screen transitions.
                    if (backgroundCheckCount >= 3) {
                        PausaAccessibilityService.endSession(packageName)
                        stopSelf()
                        return
                    }
                } else {
                    backgroundCheckCount = 0 // reset on foreground confirmation
                }

                elapsedSeconds++
                val remaining = maxSeconds - elapsedSeconds

                val nm = getSystemService(NOTIFICATION_SERVICE) as NotificationManager
                nm.notify(NOTIFICATION_ID, buildNotification(remaining))

                if (elapsedSeconds >= maxSeconds) {
                    timer?.cancel()
                    expelUser()
                    stopSelf()
                }
            }
        }, 1000, 1000)

        return START_NOT_STICKY
    }

    private fun expelUser() {
        // Mark expelled BEFORE launching home so the AccessibilityService
        // suppresses the resulting transition events (8-second window).
        PausaAccessibilityService.markExpelled(packageName)

        // Small delay ensures markExpelled is processed before the home
        // intent fires and Android emits window-change events.
        Handler(Looper.getMainLooper()).postDelayed({
            startActivity(Intent(Intent.ACTION_MAIN).apply {
                addCategory(Intent.CATEGORY_HOME)
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            })
        }, 200)
    }

    private fun isAppInForeground(pkg: String): Boolean {
        // Strategy 1 — queryEvents with 30-second window.
        // Tracks both FOREGROUND and BACKGROUND events so a stationary user
        // (no navigation for minutes) is still correctly identified as in-foreground.
        try {
            val usm = getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
            val now = System.currentTimeMillis()
            val usageEvents = usm.queryEvents(now - 30_000, now)
            val event = UsageEvents.Event()
            var lastForegroundPkg = ""
            var lastBackgroundPkg = ""
            while (usageEvents.hasNextEvent()) {
                usageEvents.getNextEvent(event)
                when (event.eventType) {
                    UsageEvents.Event.MOVE_TO_FOREGROUND -> lastForegroundPkg = event.packageName
                    UsageEvents.Event.MOVE_TO_BACKGROUND -> lastBackgroundPkg = event.packageName
                }
            }
            // pkg moved to background more recently than foreground — not in foreground
            if (lastBackgroundPkg == pkg && lastForegroundPkg != pkg) return false
            if (lastForegroundPkg.isNotEmpty()) return lastForegroundPkg == pkg
        } catch (e: Exception) { /* fall through */ }

        // Strategy 2 — queryUsageStats with 60-second window
        try {
            val usm = getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
            val now = System.currentTimeMillis()
            val stats = usm.queryUsageStats(UsageStatsManager.INTERVAL_BEST, now - 60_000, now)
            if (!stats.isNullOrEmpty()) {
                val foreground = stats.maxByOrNull { it.lastTimeUsed }
                if (foreground != null) return foreground.packageName == pkg
            }
        } catch (e: Exception) { /* fall through */ }

        // Strategy 3 — ActivityManager (deprecated but works as last resort)
        try {
            @Suppress("DEPRECATION")
            val tasks = (getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager)
                .getRunningTasks(1)
            if (!tasks.isNullOrEmpty()) {
                return tasks[0].topActivity?.packageName == pkg
            }
        } catch (e: Exception) { /* fall through */ }

        // Default false — timer must eventually fire even if all strategies fail
        return false
    }

    private fun buildNotification(remainingSeconds: Int): Notification {
        val minutes = remainingSeconds / 60
        val seconds = remainingSeconds % 60
        val timeText = if (minutes > 0) "${minutes}m ${seconds}s" else "${seconds}s"
        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("⏱ $appName — $timeText restantes")
            .setContentText("PAUSA activo")
            .setSmallIcon(android.R.drawable.ic_lock_idle_alarm)
            .setOngoing(true)
            .setColor(Color.parseColor("#E24B4A"))
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .build()
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID, "Pausa Timer",
                NotificationManager.IMPORTANCE_LOW
            ).apply { description = "Tiempo restante en apps pausadas" }
            getSystemService(NotificationManager::class.java)
                .createNotificationChannel(channel)
        }
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onDestroy() {
        super.onDestroy()
        timer?.cancel()
        PausaAccessibilityService.endSession(packageName)
    }
}
