package com.pausa.pausa_app

import android.content.Context
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

/**
 * Sesión en curso guardada en disco (pausa_prefs) para que sobreviva a que
 * el sistema mate el proceso, más el uso acumulado por app y día.
 *
 * El acumulado diario (`used_seconds_<yyyyMMdd>_<paquete>`) todavía no se usa
 * para limitar: es la base del límite diario acumulado decidido en CLAUDE.md.
 */
object SessionStore {

    data class Session(
        val packageName: String,
        val appName: String,
        val startMs: Long,
        val maxSeconds: Int,
        /** Último momento en que el temporizador vio la sesión viva. */
        val lastSeenMs: Long,
    )

    private const val PREFS = "pausa_prefs"
    private const val KEY_PKG = "session_pkg"
    private const val KEY_APP_NAME = "session_app_name"
    private const val KEY_START_MS = "session_start_ms"
    private const val KEY_MAX_SECONDS = "session_max_seconds"
    private const val KEY_LAST_SEEN_MS = "session_last_seen_ms"
    private const val USED_PREFIX = "used_seconds_"

    private fun prefs(context: Context) =
        context.applicationContext.getSharedPreferences(PREFS, Context.MODE_PRIVATE)

    private fun day(ms: Long): String =
        SimpleDateFormat("yyyyMMdd", Locale.getDefault()).format(Date(ms))

    /** Guarda una sesión nueva (sustituye a la que hubiera). */
    fun start(context: Context, packageName: String, appName: String, startMs: Long, maxSeconds: Int) {
        prefs(context).edit()
            .putString(KEY_PKG, packageName)
            .putString(KEY_APP_NAME, appName)
            .putLong(KEY_START_MS, startMs)
            .putInt(KEY_MAX_SECONDS, maxSeconds)
            .putLong(KEY_LAST_SEEN_MS, startMs)
            .apply()
    }

    /** Anota que la sesión sigue viva ahora. */
    fun heartbeat(context: Context, nowMs: Long = System.currentTimeMillis()) {
        val p = prefs(context)
        if (p.getString(KEY_PKG, "").isNullOrEmpty()) return
        p.edit().putLong(KEY_LAST_SEEN_MS, nowMs).apply()
    }

    fun load(context: Context): Session? {
        val p = prefs(context)
        val pkg = p.getString(KEY_PKG, "") ?: ""
        val startMs = p.getLong(KEY_START_MS, 0L)
        val maxSeconds = p.getInt(KEY_MAX_SECONDS, 0)
        if (pkg.isEmpty() || startMs <= 0L || maxSeconds <= 0) return null
        return Session(
            packageName = pkg,
            appName = p.getString(KEY_APP_NAME, pkg) ?: pkg,
            startMs = startMs,
            maxSeconds = maxSeconds,
            lastSeenMs = p.getLong(KEY_LAST_SEEN_MS, startMs),
        )
    }

    /**
     * Cierra la sesión guardada de [packageName] y suma lo usado al acumulado
     * del día. Con [endMs] nulo se cuenta solo hasta el último latido: es lo
     * que hay que usar cuando no se sabe si la app siguió delante (proceso
     * muerto, sesión restaurada).
     */
    fun end(context: Context, packageName: String, endMs: Long?) {
        val s = load(context) ?: return
        if (s.packageName != packageName) return
        val end = endMs ?: s.lastSeenMs
        val used = ((end - s.startMs) / 1000L).coerceIn(0L, s.maxSeconds.toLong()).toInt()
        val p = prefs(context)
        val dayPrefix = USED_PREFIX + day(s.startMs) + "_"
        val usedKey = dayPrefix + s.packageName
        val editor = p.edit()
            .remove(KEY_PKG)
            .remove(KEY_APP_NAME)
            .remove(KEY_START_MS)
            .remove(KEY_MAX_SECONDS)
            .remove(KEY_LAST_SEEN_MS)
            .putInt(usedKey, p.getInt(usedKey, 0) + used)
        // Los acumulados de otros días ya no sirven.
        for (key in p.all.keys) {
            if (key.startsWith(USED_PREFIX) && !key.startsWith(dayPrefix)) editor.remove(key)
        }
        editor.apply()
    }

    /** Segundos de sesión acumulados hoy para [packageName] (sin la sesión en curso). */
    fun usedSecondsToday(context: Context, packageName: String): Int =
        prefs(context).getInt(USED_PREFIX + day(System.currentTimeMillis()) + "_" + packageName, 0)
}
