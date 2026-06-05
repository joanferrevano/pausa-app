package com.pausa.pausa_app

import android.app.usage.UsageEvents
import android.app.usage.UsageStatsManager
import android.content.Context
import android.graphics.Bitmap
import android.graphics.Canvas
import java.io.ByteArrayOutputStream
import java.util.Calendar

object UsageStatsHelper {

    private val unproductivePackages = setOf(
        "com.instagram.android",
        "com.zhiliaoapp.musically",
        "com.google.android.youtube",
        "com.twitter.android",
        "com.facebook.katana",
        "com.snapchat.android",
        "com.netflix.mediaclient",
        "tv.twitch.android.app",
        "com.reddit.frontpage",
        "com.pinterest",
    )

    private fun getMidnight(): Long {
        return Calendar.getInstance().apply {
            set(Calendar.HOUR_OF_DAY, 0)
            set(Calendar.MINUTE, 0)
            set(Calendar.SECOND, 0)
            set(Calendar.MILLISECOND, 0)
        }.timeInMillis
    }

    fun getTodayUsageMap(context: Context): Map<String, Long> {
        val usm = context.getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
        val startTime = getMidnight()
        val endTime = System.currentTimeMillis()

        val events = usm.queryEvents(startTime, endTime)
        val event = UsageEvents.Event()

        val foregroundTimes = mutableMapOf<String, Long>()
        val lastForeground = mutableMapOf<String, Long>()

        while (events.hasNextEvent()) {
            events.getNextEvent(event)
            when (event.eventType) {
                UsageEvents.Event.MOVE_TO_FOREGROUND -> {
                    lastForeground[event.packageName] = event.timeStamp
                }
                UsageEvents.Event.MOVE_TO_BACKGROUND -> {
                    val start = lastForeground.remove(event.packageName)
                    if (start != null) {
                        val duration = event.timeStamp - start
                        foregroundTimes[event.packageName] =
                            (foregroundTimes[event.packageName] ?: 0L) + duration
                    }
                }
            }
        }

        val now = System.currentTimeMillis()
        for ((pkg, start) in lastForeground) {
            foregroundTimes[pkg] = (foregroundTimes[pkg] ?: 0L) + (now - start)
        }

        return foregroundTimes
    }

    fun getTodayUsage(context: Context): List<Map<String, Any>> {
        val usageMap = getTodayUsageMap(context)
        val pm = context.packageManager

        return usageMap
            .filter { it.value > 60_000L }
            .entries
            .sortedByDescending { it.value }
            .take(10)
            .map { (pkg, ms) ->
                val appName = try {
                    pm.getApplicationLabel(pm.getApplicationInfo(pkg, 0)).toString()
                } catch (e: Exception) { pkg }
                mapOf(
                    "packageName" to pkg,
                    "appName" to appName,
                    "totalTimeMs" to ms,
                    "category" to 0
                )
            }
    }

    fun getTotalScreenTimeMs(context: Context): Long {
        return getTodayUsageMap(context).values.sum()
    }

    fun getProductiveTimeMs(context: Context): Long {
        return getTodayUsageMap(context)
            .filter { it.key !in unproductivePackages }
            .values.sum()
    }

    fun getUnproductiveTimeMs(context: Context): Long {
        return getTodayUsageMap(context)
            .filter { it.key in unproductivePackages }
            .values.sum()
    }

    fun hasPermission(context: Context): Boolean {
        return try {
            val usm = context.getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
            val now = System.currentTimeMillis()
            val stats = usm.queryUsageStats(UsageStatsManager.INTERVAL_DAILY, now - 1000, now)
            stats != null && stats.isNotEmpty()
        } catch (e: Exception) { false }
    }

    fun getAppIcon(context: Context, packageName: String): ByteArray? {
        return try {
            val pm = context.packageManager
            val drawable = pm.getApplicationIcon(packageName)
            val bitmap = Bitmap.createBitmap(
                drawable.intrinsicWidth.coerceAtLeast(1),
                drawable.intrinsicHeight.coerceAtLeast(1),
                Bitmap.Config.ARGB_8888
            )
            val canvas = Canvas(bitmap)
            drawable.setBounds(0, 0, canvas.width, canvas.height)
            drawable.draw(canvas)
            val stream = ByteArrayOutputStream()
            bitmap.compress(Bitmap.CompressFormat.PNG, 100, stream)
            stream.toByteArray()
        } catch (e: Exception) { null }
    }
}
