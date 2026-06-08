package com.pausa.pausa_app

import android.accessibilityservice.AccessibilityService
import android.accessibilityservice.AccessibilityServiceInfo
import android.app.usage.UsageEvents
import android.app.usage.UsageStatsManager
import android.content.Context
import android.content.Intent
import android.os.Handler
import android.os.Looper
import android.util.Log
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
            Log.d("PausaDebug", "poller — current: $current / last: $lastForegroundPackage / isExpelling: $isExpelling")
            // PAUSA itself came to foreground — do NOT stop timer here.
            // MainActivity.onResume handles this exclusively via PausaTimerService.stopAll()
            // so there is exactly one stop path and no race condition.
            if (current == applicationContext.packageName ||
                current.startsWith("com.pausa.")) {
                lastForegroundPackage = current
                handler.postDelayed(this, 1000)
                return
            }
            // Home or task switcher — handle and force-reset lastForegroundPackage so
            // the next app open is always detected as a new event.
            if (current in homeAndLauncherPackages || current in taskSwitcherPackages) {
                handleAppChange(current)
                lastForegroundPackage = ""
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
        // SystemUI = status bar + notification shade, NOT a task switcher.
        // On MIUI, swiping down the notification shade fires SystemUI events —
        // keeping it here (not in taskSwitcherPackages) prevents session kills.
        "com.android.systemui",
        "android",
        "com.android.settings",
        "com.android.phone",
        "com.android.inputmethod.latin",
        // MIUI system UI surfaces — appear on notification shade swipe, screenshot, etc.
        "miui.systemui.plugin",
        "com.miui.systemui",
        "com.miui.notificationmanager",
        "com.miui.securitycenter",
        "com.miui.screenshot",
        "com.miui.mediaviewer",
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
        // com.android.systemui intentionally excluded — it fires on notification shade
        // swipe too, which would kill sessions. Moved to ignoredPackages instead.
        // MIUI recents is part of the home package
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
        // Only clear state if no timer is running. If a session is active (user is inside
        // a blocked app with the timer counting down), preserve it — clearAll would
        // wipe activeSessionApps and cause the next app event to re-intercept.
        if (!PausaTimerService.isRunning) {
            clearAll()
            Log.d("PausaDebug", "onServiceConnected — clearAll done (no active timer), poller starting")
        } else {
            Log.d("PausaDebug", "onServiceConnected — timer running for ${PausaTimerService.currentPackage}, skipping clearAll")
        }
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
        Log.d("PausaDebug", "handleAppChange — pkg: $packageName / inSession: ${isInActiveSession(packageName)} / expelled: ${isExpelled(packageName)} / expelling: $isExpelling")

        // Our own app came to foreground — do NOT stop timer here.
        // MainActivity.onResume handles this exclusively via PausaTimerService.stopAll().
        if (packageName == applicationContext.packageName ||
            packageName.startsWith("com.pausa.")) {
            Log.d("PausaDebug", "GUARD pausa-package — skipping $packageName")
            return
        }
        if (packageName.contains("pausa")) {
            Log.d("PausaDebug", "GUARD contains-pausa — skipping $packageName")
            return
        }
        // MIUI system UI (notification shade, status bar animations, etc.)
        if (packageName.contains("miui.systemui") ||
            packageName.contains("miui.system")) {
            Log.d("PausaDebug", "GUARD miui-system — skipping $packageName")
            return
        }

        // Global expulsion guard — ignore all events for 10 seconds after any expulsion
        // to prevent the crash loop caused by our MainActivity coming to foreground
        if (isExpelling) {
            Log.d("PausaDebug", "GUARD isExpelling — skipping $packageName")
            return
        }

        // Home / launcher came to foreground — end active session
        if (packageName in homeAndLauncherPackages) {
            Log.d("PausaDebug", "GUARD home-launcher — ending session for $lastForegroundPackage")
            if (lastForegroundPackage in activeSessionApps) {
                sendStopTimer(lastForegroundPackage)
                endSession(lastForegroundPackage)
            }
            lastForegroundPackage = "" // ALWAYS reset so next app open is detected fresh
            return
        }

        // Task switcher — transient UI, do NOT end the session.
        // The user may return to the same app; only reset lastForegroundPackage so
        // the next foreground app is detected correctly.
        if (packageName in taskSwitcherPackages) {
            Log.d("PausaDebug", "GUARD task-switcher — resetting last (no session end) for $lastForegroundPackage")
            lastForegroundPackage = ""
            return
        }

        if (packageName in ignoredPackages) {
            Log.d("PausaDebug", "GUARD ignoredPackages — skipping $packageName")
            return
        }
        if (packageName.startsWith("com.android.") &&
            packageName != "com.android.chrome") {
            Log.d("PausaDebug", "GUARD com.android.* — skipping $packageName")
            return
        }

        // Recently expelled — suppress BEFORE active-session check.
        // markExpelled removes from activeSessionApps, but the ordering makes
        // intent explicit and guards against any future state inconsistency.
        if (isExpelled(packageName)) {
            Log.d("PausaDebug", "GUARD isExpelled — suppressing $packageName")
            expelledApps.remove(packageName)
            return
        }

        // In active session — pass through freely
        if (isInActiveSession(packageName)) {
            Log.d("PausaDebug", "GUARD inActiveSession — passing through $packageName")
            return
        }

        // Different app came to foreground — end previous session
        if (lastForegroundPackage != packageName &&
            lastForegroundPackage in activeSessionApps) {
            Log.d("PausaDebug", "ending previous session for $lastForegroundPackage (new app: $packageName)")
            sendStopTimer(lastForegroundPackage)
            endSession(lastForegroundPackage)
        }

        // Check if this app has an active pausa
        val pausaConfig = getPausaForPackage(packageName) ?: run {
            Log.d("PausaDebug", "no pausa config for $packageName — skipping")
            return
        }

        Log.d("PausaDebug", "INTERCEPTING — launching interstitial for $packageName")
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
