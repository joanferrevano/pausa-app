package com.pausa.pausa_app

import android.content.ComponentName
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import org.json.JSONArray

class MainActivity : FlutterActivity() {

    private val channel = "com.pausa.pausa_app/usage_stats"
    private val accessibilityChannel = "com.pausa.pausa_app/accessibility"

    private companion object {
        const val REQUEST_NOTIFICATIONS = 4101
        const val KEY_NOTIF_DIALOG_BLOCKED = "notif_dialog_blocked"
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        PausaKeepaliveService.start(this)
    }

    override fun onResume() {
        super.onResume()
        // Defer timer stop to avoid ANR — Flutter initialization and PausaTimerService
        // both run on the main thread. Calling stopAll() synchronously during onResume
        // while Flutter is still loading causes a deadlock on low-end devices (MIUI).
        Handler(Looper.getMainLooper()).postDelayed({
            PausaTimerService.stopAll()
        }, 300)
    }

    // Handles relaunches when launchMode="singleTop" brings the existing instance
    // to the front (e.g. returning from accessibility settings). Flutter needs
    // setIntent so plugins that inspect the intent see the latest one.
    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channel)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "hasPermission" -> Thread {
                        try {
                            val r = UsageStatsHelper.hasPermission(this)
                            runOnUiThread { result.success(r) }
                        } catch (e: Exception) {
                            runOnUiThread { result.error("USAGE_STATS_ERROR", e.message, null) }
                        }
                    }.start()

                    "getTodayUsage" -> Thread {
                        try {
                            val r = UsageStatsHelper.getTodayUsage(this)
                            runOnUiThread { result.success(r) }
                        } catch (e: Exception) {
                            runOnUiThread { result.error("USAGE_STATS_ERROR", e.message, null) }
                        }
                    }.start()

                    "getTotalScreenTimeMs" -> Thread {
                        try {
                            val r = UsageStatsHelper.getTotalScreenTimeMs(this)
                            runOnUiThread { result.success(r) }
                        } catch (e: Exception) {
                            runOnUiThread { result.error("USAGE_STATS_ERROR", e.message, null) }
                        }
                    }.start()

                    "getProductiveTimeMs" -> Thread {
                        try {
                            val r = UsageStatsHelper.getProductiveTimeMs(this)
                            runOnUiThread { result.success(r) }
                        } catch (e: Exception) {
                            runOnUiThread { result.error("USAGE_STATS_ERROR", e.message, null) }
                        }
                    }.start()

                    "getUnproductiveTimeMs" -> Thread {
                        try {
                            val r = UsageStatsHelper.getUnproductiveTimeMs(this)
                            runOnUiThread { result.success(r) }
                        } catch (e: Exception) {
                            runOnUiThread { result.error("USAGE_STATS_ERROR", e.message, null) }
                        }
                    }.start()

                    "openUsageAccessSettings" -> {
                        startActivity(Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS))
                        result.success(null)
                    }

                    "getInstalledApps" -> Thread {
                        try {
                            val apps = UsageStatsHelper.getInstalledApps(this)
                            runOnUiThread { result.success(apps) }
                        } catch (e: Exception) {
                            runOnUiThread { result.error("USAGE_STATS_ERROR", e.message, null) }
                        }
                    }.start()

                    "getAppIcon" -> {
                        val packageName = call.argument<String>("packageName") ?: ""
                        Thread {
                            try {
                                val icon = UsageStatsHelper.getAppIcon(this, packageName)
                                runOnUiThread { result.success(icon) }
                            } catch (e: Exception) {
                                runOnUiThread { result.success(null) }
                            }
                        }.start()
                    }

                    else -> result.notImplemented()
                }
            }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, accessibilityChannel)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "isAccessibilityEnabled" -> {
                        result.success(isAccessibilityServiceEnabled())
                    }
                    "isAccessibilityRunning" -> {
                        result.success(PausaAccessibilityService.isConnected)
                    }
                    "isXiaomi" -> {
                        result.success(isXiaomiDevice())
                    }
                    "openAutostartSettings" -> {
                        result.success(openAutostartSettings())
                    }
                    "openAppDetails" -> {
                        openAppDetails()
                        result.success(null)
                    }
                    "openAccessibilitySettings" -> {
                        startActivity(Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS))
                        result.success(null)
                    }
                    "sdkInt" -> {
                        result.success(Build.VERSION.SDK_INT)
                    }
                    "areNotificationsEnabled" -> {
                        result.success(areNotificationsEnabled())
                    }
                    "requestNotifications" -> {
                        requestNotifications(result)
                    }
                    "syncPausas" -> {
                        val pausasList = call.argument<List<Map<String, Any>>>("pausas") ?: emptyList()
                        val json = JSONArray(pausasList).toString()
                        val prefs = getSharedPreferences("pausa_prefs", MODE_PRIVATE)
                        prefs.edit().putString("pausas_list", json).apply()
                        result.success(null)
                    }
                    "isInDailyCooldown" -> {
                        val pkg = call.argument<String>("packageName") ?: ""
                        result.success(PausaAccessibilityService.isInDailyCooldown(pkg, applicationContext))
                    }
                    "resetDailyCooldown" -> {
                        val pkg = call.argument<String>("packageName") ?: ""
                        PausaAccessibilityService.resetDailyCooldown(applicationContext, pkg)
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    // ── Notificaciones ────────────────────────────────────────────────────────

    private var pendingNotificationResult: MethodChannel.Result? = null

    private fun areNotificationsEnabled(): Boolean =
        androidx.core.app.NotificationManagerCompat.from(this).areNotificationsEnabled()

    /**
     * Pide el permiso de notificaciones. En Android 13+ muestra el diálogo del
     * sistema mientras el sistema lo permita; cuando ya no lo muestra (denegado
     * dos veces) o en versiones anteriores, abre los ajustes de notificaciones
     * de Pausa. Responde true solo si quedan concedidas en el momento.
     */
    private fun requestNotifications(result: MethodChannel.Result) {
        if (areNotificationsEnabled()) {
            result.success(true)
            return
        }
        val prefs = getSharedPreferences("pausa_prefs", MODE_PRIVATE)
        val dialogBlocked = prefs.getBoolean(KEY_NOTIF_DIALOG_BLOCKED, false)
        if (Build.VERSION.SDK_INT >= 33 && !dialogBlocked && pendingNotificationResult == null) {
            pendingNotificationResult = result
            requestPermissions(
                arrayOf(android.Manifest.permission.POST_NOTIFICATIONS),
                REQUEST_NOTIFICATIONS
            )
        } else {
            openNotificationSettings()
            result.success(false)
        }
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode != REQUEST_NOTIFICATIONS) return
        val granted = grantResults.isNotEmpty() &&
            grantResults[0] == android.content.pm.PackageManager.PERMISSION_GRANTED
        if (!granted && Build.VERSION.SDK_INT >= 33 &&
            !shouldShowRequestPermissionRationale(android.Manifest.permission.POST_NOTIFICATIONS)) {
            // El sistema ya no volverá a mostrar el diálogo: la próxima vez se
            // abren directamente los ajustes.
            getSharedPreferences("pausa_prefs", MODE_PRIVATE).edit()
                .putBoolean(KEY_NOTIF_DIALOG_BLOCKED, true).apply()
        }
        pendingNotificationResult?.success(granted)
        pendingNotificationResult = null
    }

    private fun openNotificationSettings() {
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                startActivity(
                    Intent(Settings.ACTION_APP_NOTIFICATION_SETTINGS)
                        .putExtra(Settings.EXTRA_APP_PACKAGE, packageName)
                )
            } else {
                openAppDetails()
            }
        } catch (e: Exception) {
            openAppDetails()
        }
    }

    // Xiaomi, Redmi y POCO (MIUI / HyperOS) matan el proceso al limpiar recientes
    // y no lo relanzan sin el permiso propio de "Inicio automático".
    private fun isXiaomiDevice(): Boolean {
        val names = listOf(Build.MANUFACTURER, Build.BRAND).map { it.lowercase() }
        return names.any { n -> listOf("xiaomi", "redmi", "poco").any { n.contains(it) } }
    }

    /** Abre la lista de Inicio automático de MIUI; si no existe, la ficha de la app. */
    private fun openAutostartSettings(): Boolean {
        return try {
            startActivity(
                Intent().setComponent(
                    ComponentName(
                        "com.miui.securitycenter",
                        "com.miui.permcenter.autostart.AutoStartManagementActivity"
                    )
                )
            )
            true
        } catch (e: Exception) {
            openAppDetails()
            false
        }
    }

    private fun openAppDetails() {
        try {
            startActivity(
                Intent(
                    Settings.ACTION_APPLICATION_DETAILS_SETTINGS,
                    Uri.fromParts("package", packageName, null)
                )
            )
        } catch (e: Exception) {
            startActivity(Intent(Settings.ACTION_SETTINGS))
        }
    }

    private fun isAccessibilityServiceEnabled(): Boolean {
        val prefString = Settings.Secure.getString(
            contentResolver,
            Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES
        ) ?: return false
        return prefString.contains("${packageName}/${packageName}.PausaAccessibilityService")
    }
}
