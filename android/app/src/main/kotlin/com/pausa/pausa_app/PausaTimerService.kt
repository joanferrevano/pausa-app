package com.pausa.pausa_app

import android.app.*
import android.content.Context
import android.content.Intent
import android.graphics.Color
import android.os.*
import androidx.core.app.NotificationCompat
import android.app.usage.UsageStatsManager
import java.util.Timer
import java.util.TimerTask

class PausaTimerService : Service() {

    private var timer: Timer? = null
    private var packageName = ""
    private var appName = ""
    private var maxMinutes = 20
    private var elapsedSeconds = 0

    companion object {
        const val CHANNEL_ID = "pausa_timer_channel"
        const val NOTIFICATION_ID = 1001
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        packageName = intent?.getStringExtra("packageName") ?: return START_NOT_STICKY
        appName = intent.getStringExtra("appName") ?: packageName
        maxMinutes = intent.getIntExtra("maxMinutes", 20)
        elapsedSeconds = 0

        createNotificationChannel()
        startForeground(NOTIFICATION_ID, buildNotification(maxMinutes * 60))

        timer = Timer()
        timer?.scheduleAtFixedRate(object : TimerTask() {
            override fun run() {
                elapsedSeconds++
                val remainingSeconds = (maxMinutes * 60) - elapsedSeconds

                val notificationManager = getSystemService(NOTIFICATION_SERVICE) as NotificationManager
                notificationManager.notify(NOTIFICATION_ID, buildNotification(remainingSeconds))

                if (elapsedSeconds >= maxMinutes * 60) {
                    timer?.cancel()
                    expelUser()
                    stopSelf()
                    return
                }

                if (elapsedSeconds % 5 == 0) {
                    if (!isAppInForeground(packageName)) {
                        timer?.cancel()
                        stopSelf()
                    }
                }
            }
        }, 1000, 1000)

        return START_NOT_STICKY
    }

    private fun expelUser() {
        PausaAccessibilityService.removeActiveTimer(packageName)
        PausaAccessibilityService.allowedApps.remove(packageName)

        val intent = Intent(this, PausaInterstitialActivity::class.java).apply {
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            addFlags(Intent.FLAG_ACTIVITY_CLEAR_TOP)
            putExtra("packageName", packageName)
            putExtra("appName", appName)
            putExtra("waitSeconds", 0)
            putExtra("maxMinutes", 0)
            putExtra("timeUp", true)
        }
        startActivity(intent)
    }

    private fun isAppInForeground(pkg: String): Boolean {
        return try {
            val usm = getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
            val now = System.currentTimeMillis()
            val stats = usm.queryUsageStats(UsageStatsManager.INTERVAL_BEST, now - 5000, now)
            stats?.maxByOrNull { it.lastTimeUsed }?.packageName == pkg
        } catch (e: Exception) { true }
    }

    private fun buildNotification(remainingSeconds: Int): Notification {
        val minutes = remainingSeconds / 60
        val seconds = remainingSeconds % 60
        val timeText = if (minutes > 0) "${minutes}m ${seconds}s restantes" else "${seconds}s restantes"

        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("⏱ Pausa activa en $appName")
            .setContentText(timeText)
            .setSmallIcon(android.R.drawable.ic_lock_idle_alarm)
            .setOngoing(true)
            .setColor(Color.parseColor("#E24B4A"))
            .build()
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "Pausa Timer",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "Muestra el tiempo restante en apps pausadas"
            }
            val manager = getSystemService(NotificationManager::class.java)
            manager.createNotificationChannel(channel)
        }
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onDestroy() {
        super.onDestroy()
        timer?.cancel()
        PausaAccessibilityService.removeActiveTimer(packageName)
    }
}
