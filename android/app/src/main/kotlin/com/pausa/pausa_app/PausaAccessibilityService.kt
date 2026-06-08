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
            // PAUSA itself came to foreground — stop any active timer
            if (current == applicationContext.packageName ||
                current.startsWith("com.pausa.")) {
                if (lastForegroundPackage.isNotEmpty() &&
                    lastForegroundPackage in activeSessionApps) {
                    sendStopTimer(lastForegroundPackage)
                    endSession(lastForegroundPackage)
                }
                lastForegroundPackage = current
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

        // Package currently being timed — used to cancel the timer on voluntary exit.
        var activeTimerPackage: String = ""

        fun startSession(packageName: String) {
            activeSessionApps.add(packageName)
            expelledApps.remove(packageName)
            activeTimerPackage = packageName
        }

        fun endSession(packageName: String) {
            activeSessionApps.remove(packageName)
            expelledApps.remove(packageName)
            if (activeTimerPackage == packageName) activeTimerPackage = ""
        }

        fun markExpelled(packageName: String) {
            isExpelling = true
            activeSessionApps.remove(packageName)
            expelledApps[packageName] = System.currentTimeMillis() + 10000L
            // Reset global expulsion guard after 10 seconds — matches expelled window
            Handler(Looper.getMainLooper()).postDelayed({ isExpelling = false }, 10000)
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

        // Call from onServiceConnected to wipe stale state after a service restart.
        fun clearAll() {
            activeSessionApps.clear()
            expelledApps.clear()
            isExpelling = false
        }

        // True for 3 seconds after any expulsion — blocks all intercepts globally
        // to prevent the crash loop caused by our own app coming to foreground.
        var isExpelling = false
            private set
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
        // Stock Android
        "com.android.launcher",
        "com.android.launcher2",
        "com.android.launcher3",
        // Pixel / Google
        "com.google.android.apps.nexuslauncher",
        // Xiaomi / MIUI
        "com.miui.home",
        // Samsung / One UI
        "com.sec.android.app.launcher",
        "com.samsung.android.app.spage",
        // OnePlus / OxygenOS
        "net.oneplus.launcher",
        "com.oneplus.launcher",
        // Oppo / ColorOS
        "com.oppo.launcher",
        "com.coloros.launcher",
        // Realme / Realme UI
        "com.realme.launcher",
        // Vivo / Funtouch / OriginOS
        "com.vivo.launcher",
        "com.bbk.launcher2",
        // Huawei / EMUI / HarmonyOS
        "com.huawei.android.launcher",
        // LG
        "com.lge.launcher3",
        // Sony
        "com.sonyericsson.home",
        "com.sony.xperia.launcher",
        // HTC
        "com.htc.launcher",
        // Nokia
        "com.nokia.launcher",
        // Asus / ROG
        "com.asus.launcher",
        "com.asus.launcher3",
        // Nothing Phone
        "com.nothing.launcher",
        // Transsion (itel, Tecno, Infinix)
        "com.transsion.launcher",
    )

    private val taskSwitcherPackages = setOf(
        // Most ROMs route recents through SystemUI
        "com.android.systemui",
        // MIUI recents is part of the home
        "com.miui.home",
        // Samsung
        "com.sec.android.app.launcher",
        // Huawei
        "com.huawei.android.launcher",
        // OnePlus
        "net.oneplus.launcher",
        "com.oneplus.launcher",
        // Oppo / Realme
        "com.oppo.launcher",
        "com.coloros.launcher",
        "com.realme.launcher",
    )

    override fun onServiceConnected() {
        // Wipe stale session state from before the service was killed/restarted.
        clearAll()
        lastForegroundPackage = ""
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
        // Never process events from our own app
        if (packageName == applicationContext.packageName) return
        if (packageName.startsWith("com.pausa.")) return
        if (packageName == lastForegroundPackage) return // already handled

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

    /** Tell the timer service to stop for a package the user voluntarily left. */
    private fun sendStopTimer(pkg: String) {
        if (pkg.isEmpty()) return
        PausaTimerService.stopIfRunning(pkg)
    }

    private fun handleAppChange(packageName: String) {
        // Our own app came to foreground — stop any active timer (safety net;
        // primary path is the poller, but belt-and-braces for accessibility events).
        if (packageName == applicationContext.packageName ||
            packageName.startsWith("com.pausa.")) {
            if (lastForegroundPackage.isNotEmpty() &&
                lastForegroundPackage in activeSessionApps) {
                sendStopTimer(lastForegroundPackage)
                endSession(lastForegroundPackage)
            }
            return
        }
        if (packageName.contains("pausa")) return

        // Global expulsion guard — ignore all events for 10 seconds after any expulsion
        // to prevent the crash loop caused by our MainActivity coming to foreground
        if (isExpelling) return

        // Home / launcher came to foreground — end active session
        if (packageName in homeAndLauncherPackages) {
            if (lastForegroundPackage in activeSessionApps) {
                sendStopTimer(lastForegroundPackage)
                endSession(lastForegroundPackage)
            }
            lastForegroundPackage = ""
            return
        }

        // Task switcher — end active session
        if (packageName in taskSwitcherPackages) {
            if (lastForegroundPackage in activeSessionApps) {
                sendStopTimer(lastForegroundPackage)
                endSession(lastForegroundPackage)
            }
            lastForegroundPackage = ""
            return
        }

        if (packageName in ignoredPackages) return
        if (packageName.startsWith("com.android.") &&
            packageName != "com.android.chrome") return

        // Recently expelled — suppress BEFORE active-session check.
        // markExpelled removes from activeSessionApps, but the ordering makes
        // intent explicit and guards against any future state inconsistency.
        if (isExpelled(packageName)) {
            expelledApps.remove(packageName)
            return
        }

        // In active session — pass through freely
        if (isInActiveSession(packageName)) return

        // Different app came to foreground — end previous session
        if (lastForegroundPackage != packageName &&
            lastForegroundPackage in activeSessionApps) {
            sendStopTimer(lastForegroundPackage)
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
            putExtra("userInitiated", true) // marks a legitimate service intercept
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
