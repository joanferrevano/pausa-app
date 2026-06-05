package com.pausa.pausa_app

import android.app.AppOpsManager
import android.app.usage.UsageStatsManager
import android.content.Context
import android.content.pm.PackageManager
import android.graphics.Bitmap
import android.graphics.Canvas
import android.os.Process
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
        "com.spotify.music",
        "com.twitch.android.app",
    )

    fun hasPermission(context: Context): Boolean {
        val appOps = context.getSystemService(Context.APP_OPS_SERVICE) as AppOpsManager
        val mode = appOps.checkOpNoThrow(
            AppOpsManager.OPSTR_GET_USAGE_STATS,
            Process.myUid(),
            context.packageName,
        )
        return mode == AppOpsManager.MODE_ALLOWED
    }

    private fun midnightMs(): Long {
        return Calendar.getInstance().apply {
            set(Calendar.HOUR_OF_DAY, 0)
            set(Calendar.MINUTE, 0)
            set(Calendar.SECOND, 0)
            set(Calendar.MILLISECOND, 0)
        }.timeInMillis
    }

    private fun getAppName(context: Context, packageName: String): String {
        return try {
            val pm = context.packageManager
            pm.getApplicationLabel(pm.getApplicationInfo(packageName, 0)).toString()
        } catch (e: PackageManager.NameNotFoundException) {
            packageName
        }
    }

    fun getTodayUsage(context: Context): List<Map<String, Any>> {
        val startTime = midnightMs()
        val endTime = System.currentTimeMillis()
        val usm = context.getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
        val stats = usm.queryUsageStats(UsageStatsManager.INTERVAL_BEST, startTime, endTime)
            ?: return emptyList()

        return stats
            .filter { it.totalTimeInForeground > 60_000L && it.lastTimeUsed >= startTime }
            .sortedByDescending { it.totalTimeInForeground }
            .take(10)
            .map { stat ->
                mapOf(
                    "packageName" to stat.packageName,
                    "appName" to getAppName(context, stat.packageName),
                    "totalTimeMs" to stat.totalTimeInForeground,
                    "isUnproductive" to unproductivePackages.contains(stat.packageName),
                )
            }
    }

    fun getTotalScreenTimeMs(context: Context): Long {
        val startTime = midnightMs()
        val endTime = System.currentTimeMillis()
        val usm = context.getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
        val stats = usm.queryUsageStats(UsageStatsManager.INTERVAL_BEST, startTime, endTime)
            ?: return 0L
        return stats
            .filter { it.totalTimeInForeground > 60_000L && it.lastTimeUsed >= startTime }
            .sumOf { it.totalTimeInForeground }
    }

    fun getUnproductiveTimeMs(context: Context): Long {
        val startTime = midnightMs()
        val endTime = System.currentTimeMillis()
        val usm = context.getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
        val stats = usm.queryUsageStats(UsageStatsManager.INTERVAL_BEST, startTime, endTime)
            ?: return 0L
        return stats
            .filter {
                it.totalTimeInForeground > 60_000L &&
                it.lastTimeUsed >= startTime &&
                unproductivePackages.contains(it.packageName)
            }
            .sumOf { it.totalTimeInForeground }
    }

    fun getProductiveTimeMs(context: Context): Long {
        val startTime = midnightMs()
        val endTime = System.currentTimeMillis()
        val usm = context.getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
        val stats = usm.queryUsageStats(UsageStatsManager.INTERVAL_BEST, startTime, endTime)
            ?: return 0L
        return stats
            .filter {
                it.totalTimeInForeground > 60_000L &&
                it.lastTimeUsed >= startTime &&
                !unproductivePackages.contains(it.packageName)
            }
            .sumOf { it.totalTimeInForeground }
    }

    fun getAppIcon(context: Context, packageName: String): ByteArray? {
        return try {
            val pm = context.packageManager
            val drawable = pm.getApplicationIcon(packageName)
            val w = drawable.intrinsicWidth.coerceAtLeast(1)
            val h = drawable.intrinsicHeight.coerceAtLeast(1)
            val bitmap = Bitmap.createBitmap(w, h, Bitmap.Config.ARGB_8888)
            val canvas = Canvas(bitmap)
            drawable.setBounds(0, 0, canvas.width, canvas.height)
            drawable.draw(canvas)
            val stream = ByteArrayOutputStream()
            bitmap.compress(Bitmap.CompressFormat.PNG, 100, stream)
            stream.toByteArray()
        } catch (e: Exception) {
            null
        }
    }
}
