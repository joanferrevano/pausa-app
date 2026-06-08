package com.pausa.pausa_app

import android.app.*
import android.content.Intent
import android.graphics.Color
import android.os.*
import android.util.Log
import androidx.core.app.NotificationCompat

class PausaTimerService : Service() {

    private val handler = Handler(Looper.getMainLooper())
    private var packageName = ""
    private var appName = ""
    private var maxSeconds = 0

    private val timerRunnable = object : Runnable {
        override fun run() {
            val elapsed = elapsedSeconds()
            val remaining = maxSeconds - elapsed

            Log.d("PausaTimer", "tick — elapsed: ${elapsed}s / max: ${maxSeconds}s / remaining: ${remaining}s / pkg: $packageName")

            if (elapsed % 10 == 0) {
                val nm = getSystemService(NOTIFICATION_SERVICE) as NotificationManager
                nm.notify(NOTIFICATION_ID, buildNotification(remaining.coerceAtLeast(0)))
            }

            if (elapsed >= maxSeconds) {
                Log.d("PausaTimer", "TIME UP — expelling $packageName")
                expelUser()
                return // don't reschedule
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
        startActivity(Intent(Intent.ACTION_MAIN).apply {
            addCategory(Intent.CATEGORY_HOME)
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        })
        stopSelf()
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
        handler.removeCallbacks(timerRunnable)
        PausaAccessibilityService.endSession(packageName)
    }
}
