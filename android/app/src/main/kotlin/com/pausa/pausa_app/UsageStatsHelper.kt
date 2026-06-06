package com.pausa.pausa_app

import android.app.usage.UsageEvents
import android.app.usage.UsageStatsManager
import android.content.Context
import android.content.Intent
import android.content.pm.ApplicationInfo
import android.content.pm.PackageManager
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.PorterDuff
import java.io.ByteArrayOutputStream
import java.util.Calendar

object UsageStatsHelper {

    private fun isUnproductive(context: Context, packageName: String): Boolean {
        return try {
            val pm = context.packageManager
            val appInfo = pm.getApplicationInfo(packageName, 0)
            if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.O) {
                when (appInfo.category) {
                    android.content.pm.ApplicationInfo.CATEGORY_SOCIAL -> true
                    android.content.pm.ApplicationInfo.CATEGORY_VIDEO -> true
                    android.content.pm.ApplicationInfo.CATEGORY_GAME -> true
                    android.content.pm.ApplicationInfo.CATEGORY_IMAGE -> true
                    else -> false
                }
            } else {
                val patterns = listOf(
                    "instagram", "tiktok", "musically", "facebook", "snapchat",
                    "twitter", "netflix", "twitch", "youtube", "reddit", "pinterest",
                    "game", "clash", "candy", "subway"
                )
                patterns.any { packageName.lowercase().contains(it) }
            }
        } catch (e: Exception) {
            false
        }
    }

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
        var screenOff = false

        while (events.hasNextEvent()) {
            events.getNextEvent(event)
            when (event.eventType) {
                UsageEvents.Event.SCREEN_NON_INTERACTIVE -> {
                    // Screen turned off — close all foreground sessions
                    screenOff = true
                    val ts = event.timeStamp
                    for ((pkg, start) in lastForeground.toMap()) {
                        val duration = ts - start
                        if (duration > 0) {
                            foregroundTimes[pkg] = (foregroundTimes[pkg] ?: 0L) + duration
                        }
                        lastForeground.remove(pkg)
                    }
                }
                UsageEvents.Event.SCREEN_INTERACTIVE -> {
                    screenOff = false
                }
                UsageEvents.Event.MOVE_TO_FOREGROUND -> {
                    if (!screenOff) {
                        lastForeground[event.packageName] = event.timeStamp
                    }
                }
                UsageEvents.Event.MOVE_TO_BACKGROUND -> {
                    val start = lastForeground.remove(event.packageName)
                    if (start != null && !screenOff) {
                        val duration = event.timeStamp - start
                        if (duration > 0) {
                            foregroundTimes[event.packageName] =
                                (foregroundTimes[event.packageName] ?: 0L) + duration
                        }
                    }
                }
            }
        }

        // Close any still-foreground apps (currently being used)
        if (!screenOff) {
            val now = System.currentTimeMillis()
            for ((pkg, start) in lastForeground) {
                val duration = now - start
                if (duration > 0) {
                    foregroundTimes[pkg] = (foregroundTimes[pkg] ?: 0L) + duration
                }
            }
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
                    "isUnproductive" to isUnproductive(context, pkg),
                )
            }
    }

    fun getTotalScreenTimeMs(context: Context): Long =
        getTodayUsageMap(context).values.sum()

    fun getProductiveTimeMs(context: Context): Long =
        getTodayUsageMap(context).filter { !isUnproductive(context, it.key) }.values.sum()

    fun getUnproductiveTimeMs(context: Context): Long =
        getTodayUsageMap(context).filter { isUnproductive(context, it.key) }.values.sum()

    fun hasPermission(context: Context): Boolean {
        return try {
            val usm = context.getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
            val now = System.currentTimeMillis()
            val stats = usm.queryUsageStats(
                UsageStatsManager.INTERVAL_DAILY,
                now - 1000L * 60 * 60 * 24,
                now,
            )
            stats != null && stats.isNotEmpty()
        } catch (e: Exception) { false }
    }

    fun getInstalledApps(context: Context): List<Map<String, Any>> {
        val pm = context.packageManager
        val results = mutableMapOf<String, String>()

        // Strategy 1: getLaunchIntentForPackage — most reliable on stock Android
        try {
            pm.getInstalledPackages(PackageManager.GET_META_DATA).forEach { pkgInfo ->
                val pkgName = pkgInfo?.packageName ?: return@forEach
                val appInfo = pkgInfo.applicationInfo ?: return@forEach
                if (pm.getLaunchIntentForPackage(pkgName) != null &&
                    pkgName != context.packageName) {
                    val name = try {
                        pm.getApplicationLabel(appInfo).toString()
                    } catch (e: Exception) { pkgName }
                    results[pkgName] = name
                }
            }
        } catch (e: Exception) {}

        // Strategy 2: ACTION_MAIN + CATEGORY_LAUNCHER — catches MIUI-specific apps
        try {
            val intent = Intent(Intent.ACTION_MAIN, null).apply {
                addCategory(Intent.CATEGORY_LAUNCHER)
            }
            val flag = if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.M)
                PackageManager.MATCH_ALL else 0
            pm.queryIntentActivities(intent, flag).forEach { info ->
                val pkg = info?.activityInfo?.packageName ?: return@forEach
                if (pkg != context.packageName) {
                    val label = try {
                        info.loadLabel(pm).toString()
                    } catch (e: Exception) { pkg }
                    results[pkg] = label
                }
            }
        } catch (e: Exception) {}

        // Strategy 3: getInstalledApplications — catches remaining user apps on MIUI
        try {
            pm.getInstalledApplications(PackageManager.GET_META_DATA).forEach { appInfo ->
                val pkg = appInfo?.packageName ?: return@forEach
                if (pkg !in results && pkg != context.packageName) {
                    val hasLauncher = pm.getLaunchIntentForPackage(pkg) != null
                    val isUserApp = (appInfo.flags and ApplicationInfo.FLAG_SYSTEM) == 0
                    if (hasLauncher || isUserApp) {
                        val label = try {
                            pm.getApplicationLabel(appInfo).toString()
                        } catch (e: Exception) { pkg }
                        results[pkg] = label
                    }
                }
            }
        } catch (e: Exception) {}

        return results.entries
            .map { (pkg, name) -> mapOf("packageName" to pkg, "appName" to name) }
            .sortedBy { it["appName"] as String }
    }

    fun getAppIcon(context: Context, packageName: String): ByteArray? {
        return try {
            val pm = context.packageManager
            val drawable = try {
                pm.getApplicationIcon(packageName)
            } catch (e: PackageManager.NameNotFoundException) {
                return null
            }

            val density = context.resources.displayMetrics.density
            val size = (48 * density).toInt().coerceAtLeast(48)

            val bitmap = Bitmap.createBitmap(size, size, Bitmap.Config.ARGB_8888)
            val canvas = Canvas(bitmap)
            canvas.drawColor(android.graphics.Color.TRANSPARENT, PorterDuff.Mode.CLEAR)
            drawable.setBounds(0, 0, size, size)
            drawable.draw(canvas)

            val stream = ByteArrayOutputStream()
            bitmap.compress(Bitmap.CompressFormat.PNG, 100, stream)
            bitmap.recycle()
            stream.toByteArray()
        } catch (e: Exception) { null }
    }
}
