package com.pausa.pausa_app

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

/**
 * Arranca el keepalive al encender el móvil y al actualizar la app, sin esperar
 * a que el usuario abra Pausa. El servicio de accesibilidad lo relanza el sistema.
 */
class BootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        when (intent.action) {
            Intent.ACTION_BOOT_COMPLETED,
            Intent.ACTION_MY_PACKAGE_REPLACED -> {
                PausaLog.d("PausaDebug", "BootReceiver — ${intent.action}, arrancando keepalive")
                PausaKeepaliveService.start(context)
            }
        }
    }
}
