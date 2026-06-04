package com.pausa.pausa_app

import android.app.AppOpsManager
import android.app.usage.UsageStatsManager
import android.content.Context
import android.content.pm.PackageManager
import android.os.Process
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

    private fun todayRange(): Pair<Long, Long> {
        val cal = Calendar.getInstance()
        cal.set(Calendar.HOUR_OF_DAY, 0)
        cal.set(Calendar.MINUTE, 0)
        cal.set(Calendar.SECOND, 0)
        cal.set(Calendar.MILLISECOND, 0)
        return Pair(cal.timeInMillis, System.currentTimeMillis())
    }

    private fun getAppName(context: Context, packageName: String): String {
        return try {
            val pm = context.packageManager
            val info = pm.getApplicationInfo(packageName, 0)
            pm.getApplicationLabel(info).toString()
        } catch (e: PackageManager.NameNotFoundException) {
            packageName
        }
    }

    fun getTodayUsage(context: Context): List<Map<String, Any>> {
        val (start, end) = todayRange()
        val usm = context.getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
        val stats = usm.queryUsageStats(UsageStatsManager.INTERVAL_DAILY, start, end)
            ?: return emptyList()

        return stats
            .filter { it.totalTimeInForeground >= 60_000L }
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
        val (start, end) = todayRange()
        val usm = context.getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
        val stats = usm.queryUsageStats(UsageStatsManager.INTERVAL_DAILY, start, end)
            ?: return 0L
        return stats
            .filter { it.totalTimeInForeground >= 60_000L }
            .sumOf { it.totalTimeInForeground }
    }

    fun getUnproductiveTimeMs(context: Context): Long {
        val (start, end) = todayRange()
        val usm = context.getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
        val stats = usm.queryUsageStats(UsageStatsManager.INTERVAL_DAILY, start, end)
            ?: return 0L
        return stats
            .filter { it.totalTimeInForeground >= 60_000L && unproductivePackages.contains(it.packageName) }
            .sumOf { it.totalTimeInForeground }
    }

    fun getProductiveTimeMs(context: Context): Long {
        val (start, end) = todayRange()
        val usm = context.getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
        val stats = usm.queryUsageStats(UsageStatsManager.INTERVAL_DAILY, start, end)
            ?: return 0L
        return stats
            .filter { it.totalTimeInForeground >= 60_000L && !unproductivePackages.contains(it.packageName) }
            .sumOf { it.totalTimeInForeground }
    }
}
