package com.pausa.pausa_app

import android.content.Intent
import android.os.Bundle
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private val channel = "com.pausa.pausa_app/usage_stats"

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        window.setBackgroundDrawableResource(android.R.color.black)
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
    }
}
