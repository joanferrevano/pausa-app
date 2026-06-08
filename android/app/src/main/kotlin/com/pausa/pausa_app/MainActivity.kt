package com.pausa.pausa_app

import android.content.Intent
import android.os.Build
import android.os.Bundle
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import org.json.JSONArray

class MainActivity : FlutterActivity() {

    private val channel = "com.pausa.pausa_app/usage_stats"
    private val accessibilityChannel = "com.pausa.pausa_app/accessibility"

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        window.setBackgroundDrawableResource(android.R.color.black)
        val keepaliveIntent = Intent(this, PausaKeepaliveService::class.java)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            startForegroundService(keepaliveIntent)
        } else {
            startService(keepaliveIntent)
        }
    }

    override fun onResume() {
        super.onResume()
        // User opened PAUSA — stop any running blocked-app timer so the timer
        // doesn't expire and expel the user the next time they open that app.
        sendBroadcast(Intent("com.pausa.STOP_ALL_TIMERS"))
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
                    "openAccessibilitySettings" -> {
                        startActivity(Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS))
                        result.success(null)
                    }
                    "syncPausas" -> {
                        val pausasList = call.argument<List<Map<String, Any>>>("pausas") ?: emptyList()
                        val json = JSONArray(pausasList).toString()
                        val prefs = getSharedPreferences("pausa_prefs", MODE_PRIVATE)
                        prefs.edit().putString("pausas_list", json).apply()
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
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
