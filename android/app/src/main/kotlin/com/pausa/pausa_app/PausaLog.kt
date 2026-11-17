package com.pausa.pausa_app

import android.util.Log

/**
 * Logs de diagnóstico: solo se escriben en builds de debug. En release no sale
 * nada a logcat (los logs incluían paquetes de apps y estados internos).
 */
object PausaLog {
    @JvmStatic
    fun d(tag: String, msg: String) {
        if (BuildConfig.DEBUG) Log.d(tag, msg)
    }

    @JvmStatic
    fun e(tag: String, msg: String) {
        if (BuildConfig.DEBUG) Log.e(tag, msg)
    }
}
