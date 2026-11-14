package com.pausa.pausa_app

import android.app.usage.UsageEvents
import android.app.usage.UsageStatsManager
import android.content.Context

/**
 * Averigua qué app está delante mirando una ventana larga de eventos de uso.
 *
 * Se usa cuando no vale la ventana corta del poller (2 s): al reconectar el
 * servicio de accesibilidad tras morir el proceso y al restaurar una sesión.
 */
object ForegroundHelper {

    /** Ventana por defecto para las búsquedas largas. */
    const val LONG_WINDOW_MS = 2 * 60 * 60 * 1000L

    /**
     * Devuelve el paquete del ÚLTIMO evento de "actividad al frente" de la
     * ventana, pero solo si esa actividad no se ha pausado o parado después.
     * Devuelve null si no hay eventos, si la última actividad ya no está
     * delante (pantalla apagada, bloqueo…) o si la consulta falla.
     */
    fun lastForegroundPackage(context: Context, windowMs: Long = LONG_WINDOW_MS): String? {
        return try {
            val usm = context.getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
            val now = System.currentTimeMillis()
            val events = usm.queryEvents(now - windowMs, now)
            val event = UsageEvents.Event()
            var lastPkg: String? = null
            var lastKey: String? = null
            var stillInFront = false
            while (events.hasNextEvent()) {
                events.getNextEvent(event)
                val key = "${event.packageName}/${event.className}"
                when (event.eventType) {
                    UsageEvents.Event.MOVE_TO_FOREGROUND -> {
                        lastPkg = event.packageName
                        lastKey = key
                        stillInFront = true
                    }
                    UsageEvents.Event.MOVE_TO_BACKGROUND,
                    EVENT_ACTIVITY_STOPPED -> {
                        // Solo cuenta si se va la MISMA actividad que estaba delante;
                        // al navegar dentro de una app se pausa la anterior, no la nueva.
                        if (key == lastKey) stillInFront = false
                    }
                }
            }
            if (stillInFront) lastPkg else null
        } catch (e: Exception) {
            null
        }
    }

    // UsageEvents.Event.ACTIVITY_STOPPED (API 29); el valor es estable.
    private const val EVENT_ACTIVITY_STOPPED = 23
}
