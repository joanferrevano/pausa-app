package com.pausa.pausa_app

import android.app.*
import android.content.Intent
import android.content.pm.ServiceInfo
import android.os.*
import android.util.Log
import androidx.core.app.NotificationCompat

class PausaKeepaliveService : Service() {

    companion object {
        const val CHANNEL_ID = "pausa_keepalive"
        const val NOTIFICATION_ID = 9999
    }

    override fun onCreate() {
        super.onCreate()
        createNotificationChannel()
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
                startForeground(
                    NOTIFICATION_ID,
                    buildNotification(),
                    ServiceInfo.FOREGROUND_SERVICE_TYPE_SPECIAL_USE
                )
            } else {
                startForeground(NOTIFICATION_ID, buildNotification())
            }
        } catch (e: Exception) {
            // El sistema puede negar el primer plano si el arranque vino de segundo
            // plano sin exención (Android 12+). Mejor parar que tumbar el proceso.
            Log.e("PausaDebug", "keepalive sin primer plano: $e")
            stopSelf()
        }
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        return START_STICKY
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onTaskRemoved(rootIntent: Intent?) {
        scheduleRestart()
        super.onTaskRemoved(rootIntent)
    }

    // Reinicio por alarma al quitar la tarea de recientes. En Android 8+ un
    // servicio en primer plano solo se puede arrancar desde segundo plano con
    // getForegroundService, y una alarma normal se aplaza (hasta una hora) si
    // la app está en un cubo de ahorro; setAndAllowWhileIdle evita ese aplazamiento.
    private fun scheduleRestart() {
        try {
            val restartIntent = Intent(applicationContext, PausaKeepaliveService::class.java)
            val flags = PendingIntent.FLAG_ONE_SHOT or PendingIntent.FLAG_IMMUTABLE
            val pendingIntent = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                PendingIntent.getForegroundService(applicationContext, 1, restartIntent, flags)
            } else {
                PendingIntent.getService(applicationContext, 1, restartIntent, flags)
            }
            val alarmManager = getSystemService(ALARM_SERVICE) as AlarmManager
            alarmManager.setAndAllowWhileIdle(
                AlarmManager.ELAPSED_REALTIME_WAKEUP,
                SystemClock.elapsedRealtime() + 1000,
                pendingIntent
            )
        } catch (e: Exception) {
            Log.e("PausaDebug", "no se pudo programar el reinicio del keepalive: $e")
        }
    }

    private fun buildNotification(): Notification {
        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("PAUSA")
            .setContentText("")
            .setSmallIcon(android.R.drawable.ic_lock_idle_alarm)
            .setOngoing(true)
            .setPriority(NotificationCompat.PRIORITY_MIN)
            .setVisibility(NotificationCompat.VISIBILITY_SECRET)
            .setSilent(true)
            .build()
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "PAUSA en segundo plano",
                NotificationManager.IMPORTANCE_MIN
            ).apply {
                description = "Mantiene las pausas activas"
                setShowBadge(false)
                lockscreenVisibility = Notification.VISIBILITY_SECRET
            }
            getSystemService(NotificationManager::class.java)
                .createNotificationChannel(channel)
        }
    }
}
