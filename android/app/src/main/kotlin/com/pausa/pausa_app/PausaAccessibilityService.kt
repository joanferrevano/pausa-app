package com.pausa.pausa_app

import android.accessibilityservice.AccessibilityService
import android.accessibilityservice.AccessibilityServiceInfo
import android.content.Context
import android.content.Intent
import android.os.Handler
import android.os.Looper
import android.view.accessibility.AccessibilityEvent
import org.json.JSONArray

class PausaAccessibilityService : AccessibilityService() {

    companion object {
        var instance: PausaAccessibilityService? = null

        internal val allowedApps = mutableMapOf<String, Long>()
        private val activeTimerApps = mutableSetOf<String>()

        fun allowApp(packageName: String) {
            allowedApps[packageName] = System.currentTimeMillis() + 3000L
        }

        fun addActiveTimer(packageName: String) {
            activeTimerApps.add(packageName)
        }

        fun removeActiveTimer(packageName: String) {
            activeTimerApps.remove(packageName)
            allowedApps.remove(packageName)
        }

        fun isAllowed(packageName: String): Boolean {
            val expiry = allowedApps[packageName]
            if (expiry != null && System.currentTimeMillis() < expiry) return true
            allowedApps.remove(packageName)
            return packageName in activeTimerApps
        }
    }

    private var lastPackage = ""
    private var lastPackageTime = 0L
    private val COOLDOWN_MS = 500L
    private val handler = Handler(Looper.getMainLooper())
    private var launchPending = false

    private val homePackages = setOf(
        "com.android.launcher",
        "com.android.launcher2",
        "com.android.launcher3",
        "com.google.android.apps.nexuslauncher",
        "com.sec.android.app.launcher",
        "com.miui.home",
        "net.oneplus.launcher",
        "com.oppo.launcher",
        "com.coloros.launcher",
        "com.realme.launcher",
        "com.huawei.android.launcher",
        "com.bbk.launcher2",
        "com.lge.launcher3",
        "com.htc.launcher",
        "com.sonyericsson.home",
        "com.nokia.launcher",
    )

    // Recents / task switcher — treat same as home for reset purposes
    private val taskSwitcherPackages = setOf(
        "com.android.systemui",
        "com.samsung.android.app.spage",
        "com.miui.securitycenter",
    )

    private val systemPackages = setOf(
        "android",
        "com.android.settings",
        "com.android.phone",
        "com.android.inputmethod.latin",
        "com.miui.systemAdSolution",
    )

    override fun onServiceConnected() {
        instance = this
        serviceInfo = AccessibilityServiceInfo().apply {
            eventTypes = AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED or
                    AccessibilityEvent.TYPE_WINDOWS_CHANGED
            feedbackType = AccessibilityServiceInfo.FEEDBACK_GENERIC
            flags = AccessibilityServiceInfo.FLAG_REPORT_VIEW_IDS or
                    AccessibilityServiceInfo.FLAG_INCLUDE_NOT_IMPORTANT_VIEWS
            notificationTimeout = 50
        }
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        if (event?.eventType != AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED &&
            event?.eventType != AccessibilityEvent.TYPE_WINDOWS_CHANGED) return

        val packageName = event?.packageName?.toString() ?: return
        if (packageName == applicationContext.packageName) return

        // Home — user pressed home button
        if (packageName in homePackages) {
            if (lastPackage in activeTimerApps) {
                removeActiveTimer(lastPackage)
                allowedApps.remove(lastPackage)
            }
            allowedApps.clear()
            launchPending = false
            lastPackage = ""     // RESET — next open of any app always re-evaluates
            lastPackageTime = 0L
            return
        }

        // Task switcher / recents opened
        if (packageName in taskSwitcherPackages) {
            allowedApps.clear()
            launchPending = false
            lastPackage = ""     // RESET
            lastPackageTime = 0L
            return
        }

        if (packageName in systemPackages) return
        if (packageName.startsWith("com.android.") &&
            packageName != "com.android.chrome") return

        // User is navigating inside an allowed/timer app — pass through freely
        if (isAllowed(packageName)) {
            lastPackage = packageName
            lastPackageTime = System.currentTimeMillis()
            return
        }

        val now = System.currentTimeMillis()

        // New package in foreground — check if previous was a paused app
        if (packageName != lastPackage && lastPackage.isNotEmpty()) {
            if (lastPackage in activeTimerApps) {
                removeActiveTimer(lastPackage)
                allowedApps.remove(lastPackage)
            }
            // If last package was a blocked app, reset so next open re-triggers
            if (getPausaForPackage(lastPackage) != null) {
                lastPackage = ""
                lastPackageTime = 0L
            }
            launchPending = false
        }

        // Cooldown — only blocks duplicate events for the EXACT same package
        if (packageName == lastPackage && (now - lastPackageTime) < COOLDOWN_MS) return
        if (launchPending) return

        val pausaConfig = getPausaForPackage(packageName) ?: run {
            lastPackage = packageName
            lastPackageTime = now
            return
        }

        allowedApps.remove(packageName)
        removeActiveTimer(packageName)

        lastPackage = packageName
        lastPackageTime = now
        launchPending = true

        startActivity(Intent(this, PausaInterstitialActivity::class.java).apply {
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            addFlags(Intent.FLAG_ACTIVITY_CLEAR_TOP)
            addFlags(Intent.FLAG_ACTIVITY_SINGLE_TOP)
            putExtra("packageName", packageName)
            putExtra("appName", pausaConfig.first)
            putExtra("waitSeconds", pausaConfig.second)
            putExtra("maxMinutes", pausaConfig.third)
        })

        handler.postDelayed({ launchPending = false }, 600L)
    }

    override fun onInterrupt() {}

    override fun onDestroy() {
        super.onDestroy()
        if (instance === this) instance = null
    }

    private fun getPausaForPackage(packageName: String): Triple<String, Int, Int>? {
        val prefs = applicationContext.getSharedPreferences("pausa_prefs", Context.MODE_PRIVATE)
        val json = prefs.getString("pausas_list", "[]") ?: return null
        return try {
            val array = JSONArray(json)
            for (i in 0 until array.length()) {
                val obj = array.getJSONObject(i)
                if (obj.getString("packageName") == packageName && obj.getBoolean("isActive")) {
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
