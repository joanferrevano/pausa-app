package com.pausa.pausa_app

import android.app.*
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
            override fun run() {
                elapsedSeconds++
                val remaining = maxSeconds - elapsedSeconds

                // Update notification every 10 seconds to reduce overhead
                if (elapsedSeconds % 10 == 0) {
                    val nm = getSystemService(NOTIFICATION_SERVICE) as NotificationManager
                    nm.notify(NOTIFICATION_ID, buildNotification(remaining))
                }

                // Time is up — expel unconditionally
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
        PausaAccessibilityService.markExpelled(packageName)
        Handler(Looper.getMainLooper()).postDelayed({
            startActivity(Intent(Intent.ACTION_MAIN).apply {
                addCategory(Intent.CATEGORY_HOME)
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            })
        }, 200)
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
