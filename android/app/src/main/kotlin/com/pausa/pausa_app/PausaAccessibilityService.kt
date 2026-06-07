package com.pausa.pausa_app

import android.accessibilityservice.AccessibilityService
import android.accessibilityservice.AccessibilityServiceInfo
import android.app.usage.UsageEvents
import android.app.usage.UsageStatsManager
import android.content.Context
import android.content.Intent
import android.os.Handler
import android.os.Looper
import android.view.accessibility.AccessibilityEvent

class PausaAccessibilityService : AccessibilityService() {

    private var lastForegroundPackage = ""
    private val handler = Handler(Looper.getMainLooper())

    // Polls UsageStats every second as a backup — catches resumptions that
    // don't fire a strong enough AccessibilityEvent (e.g. task resume).
    private val foregroundPoller = object : Runnable {
        override fun run() {
            val current = getCurrentForegroundApp() ?: run {
                handler.postDelayed(this, 1000)
                return
            }
            if (current != lastForegroundPackage) {
                handleAppChange(current)
                lastForegroundPackage = current
            }
            handler.postDelayed(this, 1000)
        }
    }

    companion object {
        private val activeSessionApps = mutableSetOf<String>()
        private val expelledApps = mutableMapOf<String, Long>()

        fun startSession(packageName: String) {
            activeSessionApps.add(packageName)
            expelledApps.remove(packageName)
        }

        fun endSession(packageName: String) {
            activeSessionApps.remove(packageName)
            expelledApps.remove(packageName)
        }

        fun markExpelled(packageName: String) {
            activeSessionApps.remove(packageName)
            expelledApps[packageName] = System.currentTimeMillis() + 8000L
        }

        fun isInActiveSession(packageName: String): Boolean =
            packageName in activeSessionApps

        fun isExpelled(packageName: String): Boolean {
            val expiry = expelledApps[packageName] ?: return false
            if (System.currentTimeMillis() > expiry) {
                expelledApps.remove(packageName)
                return false
            }
            return true
        }
    }

    private val ignoredPackages = setOf(
        "com.pausa.pausa_app",
        "com.android.systemui",
        "android",
        "com.android.settings",
        "com.android.phone",
        "com.android.inputmethod.latin",
    )

    private val homeAndLauncherPackages = setOf(
        "com.miui.home",
        "com.android.launcher",
        "com.android.launcher2",
        "com.android.launcher3",
        "com.google.android.apps.nexuslauncher",
        "com.sec.android.app.launcher",
        "com.samsung.android.app.spage",
        "net.oneplus.launcher",
        "com.oppo.launcher",
        "com.coloros.launcher",
        "com.realme.launcher",
        "com.bbk.launcher2",
        "com.huawei.android.launcher",
        "com.lge.launcher3",
        "com.sonyericsson.home",
        "com.nokia.launcher",
    )

    private val taskSwitcherPackages = setOf(
        "com.android.systemui",
        "com.miui.home",
        "com.sec.android.app.launcher",
        "com.huawei.android.launcher",
        "net.oneplus.launcher",
    )

    override fun onServiceConnected() {
        serviceInfo = AccessibilityServiceInfo().apply {
            eventTypes = AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED or
                    AccessibilityEvent.TYPE_WINDOWS_CHANGED or
                    AccessibilityEvent.TYPE_VIEW_FOCUSED
            feedbackType = AccessibilityServiceInfo.FEEDBACK_GENERIC
            flags = AccessibilityServiceInfo.FLAG_REPORT_VIEW_IDS or
                    AccessibilityServiceInfo.FLAG_INCLUDE_NOT_IMPORTANT_VIEWS
            notificationTimeout = 50
        }
        handler.post(foregroundPoller)
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        if (event?.eventType != AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED &&
            event?.eventType != AccessibilityEvent.TYPE_WINDOWS_CHANGED &&
            event?.eventType != AccessibilityEvent.TYPE_VIEW_FOCUSED) return

        val packageName = event?.packageName?.toString() ?: return
        if (packageName == lastForegroundPackage) return // already handled by poller or previous event

        handleAppChange(packageName)
        lastForegroundPackage = packageName
    }

    override fun onInterrupt() {
        handler.removeCallbacks(foregroundPoller)
    }

    override fun onDestroy() {
        super.onDestroy()
        handler.removeCallbacks(foregroundPoller)
    }

    // ── Core logic — shared by onAccessibilityEvent and foregroundPoller ─────

    private fun handleAppChange(packageName: String) {
        // Home / launcher came to foreground — end active session
        if (packageName in homeAndLauncherPackages) {
            if (lastForegroundPackage in activeSessionApps) {
                endSession(lastForegroundPackage)
            }
            lastForegroundPackage = ""
            return
        }

        // Task switcher — end active session
        if (packageName in taskSwitcherPackages) {
            if (lastForegroundPackage in activeSessionApps) {
                endSession(lastForegroundPackage)
            }
            lastForegroundPackage = ""
            return
        }

        if (packageName in ignoredPackages) return
        if (packageName.startsWith("com.android.") &&
            packageName != "com.android.chrome") return

        // In active session — pass through freely
        if (isInActiveSession(packageName)) return

        // Recently expelled — suppress and consume the window
        if (isExpelled(packageName)) {
            expelledApps.remove(packageName)
            return
        }

        // Different app came to foreground — end previous session
        if (lastForegroundPackage != packageName &&
            lastForegroundPackage in activeSessionApps) {
            endSession(lastForegroundPackage)
        }

        // Check if this app has an active pausa
        val pausaConfig = getPausaForPackage(packageName) ?: return

        // Intercept — show countdown
        startActivity(Intent(this, PausaInterstitialActivity::class.java).apply {
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            addFlags(Intent.FLAG_ACTIVITY_CLEAR_TOP)
            addFlags(Intent.FLAG_ACTIVITY_SINGLE_TOP)
            putExtra("packageName", packageName)
            putExtra("appName", pausaConfig.first)
            putExtra("waitSeconds", pausaConfig.second)
            putExtra("maxMinutes", pausaConfig.third)
        })
    }

    // ── UsageStats poller ─────────────────────────────────────────────────────

    private fun getCurrentForegroundApp(): String? {
        return try {
            val usm = getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
            val now = System.currentTimeMillis()
            val events = usm.queryEvents(now - 2000, now)
            val event = UsageEvents.Event()
            var last = ""
            while (events.hasNextEvent()) {
                events.getNextEvent(event)
                if (event.eventType == UsageEvents.Event.MOVE_TO_FOREGROUND) {
                    last = event.packageName
                }
            }
            last.ifEmpty { null }
        } catch (e: Exception) { null }
    }

    // ── SharedPreferences lookup ──────────────────────────────────────────────

    private fun getPausaForPackage(packageName: String): Triple<String, Int, Int>? {
        val prefs = applicationContext.getSharedPreferences(
            "pausa_prefs", Context.MODE_PRIVATE
        )
        val json = prefs.getString("pausas_list", "[]") ?: return null
        return try {
            val array = org.json.JSONArray(json)
            for (i in 0 until array.length()) {
                val obj = array.getJSONObject(i)
                if (obj.getString("packageName") == packageName &&
                    obj.getBoolean("isActive")) {
                    return Triple(
                        obj.getString("appName"),
                        obj.getInt("waitSeconds"),
                        obj.getInt("maxMinutes")
                    )
                }
            }
            null
        } catch (e: Exception) { null }
    }
}
