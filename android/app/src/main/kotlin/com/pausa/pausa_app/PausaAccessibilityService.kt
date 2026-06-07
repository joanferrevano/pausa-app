package com.pausa.pausa_app

import android.accessibilityservice.AccessibilityService
import android.accessibilityservice.AccessibilityServiceInfo
import android.content.Context
import android.content.Intent
import android.view.accessibility.AccessibilityEvent
import org.json.JSONArray

class PausaAccessibilityService : AccessibilityService() {

    companion object {
        var instance: PausaAccessibilityService? = null
    }

    private var lastPackage = ""
    private var lastPackageTime = 0L
    private val COOLDOWN_MS = 2000L
    private val backgroundedPausedApps = mutableSetOf<String>()

    private val ignoredPackages = setOf(
        "com.android.systemui",
        // Stock Android launchers
        "com.android.launcher",
        "com.android.launcher2",
        "com.android.launcher3",
        "com.google.android.apps.nexuslauncher",
        // Samsung One UI
        "com.sec.android.app.launcher",
        "com.samsung.android.app.spage",
        // MIUI / Xiaomi / POCO
        "com.miui.home",
        "com.miui.securitycenter",
        "com.miui.systemAdSolution",
        // OnePlus / OxygenOS
        "net.oneplus.launcher",
        // Oppo / ColorOS
        "com.oppo.launcher",
        "com.coloros.launcher",
        // Realme
        "com.realme.launcher",
        // Vivo
        "com.bbk.launcher2",
        // Huawei / EMUI
        "com.huawei.android.launcher",
        // LG
        "com.lge.launcher3",
        // HTC
        "com.htc.launcher",
        // Sony
        "com.sonyericsson.home",
        // Nokia
        "com.nokia.launcher",
        // System
        "android",
        "com.android.settings",
        "com.android.phone",
        "com.android.inputmethod.latin",
    )

    override fun onServiceConnected() {
        instance = this
        val info = AccessibilityServiceInfo().apply {
            eventTypes = AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED or
                    AccessibilityEvent.TYPE_WINDOWS_CHANGED
            feedbackType = AccessibilityServiceInfo.FEEDBACK_GENERIC
            flags = AccessibilityServiceInfo.FLAG_REPORT_VIEW_IDS or
                    AccessibilityServiceInfo.FLAG_INCLUDE_NOT_IMPORTANT_VIEWS
            notificationTimeout = 50
        }
        serviceInfo = info
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        val packageName = event?.packageName?.toString() ?: return

        // Our own app (interstitial showing) — do not process
        if (packageName == applicationContext.packageName) return
        if (packageName in ignoredPackages) return
        if (packageName.startsWith("com.android.") &&
            packageName != "com.android.chrome") return

        when (event.eventType) {
            AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED,
            AccessibilityEvent.TYPE_WINDOWS_CHANGED -> {
                val now = System.currentTimeMillis()
                val isResumingFromBackground = packageName in backgroundedPausedApps
                backgroundedPausedApps.remove(packageName)

                if (!isResumingFromBackground &&
                    packageName == lastPackage &&
                    (now - lastPackageTime) < COOLDOWN_MS) return

                lastPackage = packageName
                lastPackageTime = now

                val pausaConfig = getPausaForPackage(packageName) ?: return

                // Mark as backgrounded — re-intercept if user leaves and returns
                backgroundedPausedApps.add(packageName)

                val intent = Intent(this, PausaInterstitialActivity::class.java).apply {
                    addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                    addFlags(Intent.FLAG_ACTIVITY_CLEAR_TOP)
                    addFlags(Intent.FLAG_ACTIVITY_SINGLE_TOP)
                    putExtra("packageName", packageName)
                    putExtra("appName", pausaConfig.first)
                    putExtra("waitSeconds", pausaConfig.second)
                    putExtra("maxMinutes", pausaConfig.third)
                }
                startActivity(intent)
            }
        }
    }

    override fun onInterrupt() {}

    override fun onDestroy() {
        super.onDestroy()
        if (instance === this) instance = null
    }

    fun allowPackage(packageName: String) {
        backgroundedPausedApps.remove(packageName)
    }

    private fun getPausaForPackage(packageName: String): Triple<String, Int, Int>? {
        val prefs = applicationContext.getSharedPreferences(
            "pausa_prefs", Context.MODE_PRIVATE
        )
        val json = prefs.getString("pausas_list", "[]") ?: return null
        return try {
            val array = JSONArray(json)
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
