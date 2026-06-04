package com.pausa.pausa_app

import android.content.Intent
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private val channel = "com.pausa.pausa_app/usage_stats"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channel)
            .setMethodCallHandler { call, result ->
                try {
                    when (call.method) {
                        "hasPermission" ->
                            result.success(UsageStatsHelper.hasPermission(this))

                        "getTodayUsage" ->
                            result.success(UsageStatsHelper.getTodayUsage(this))

                        "getTotalScreenTimeMs" ->
                            result.success(UsageStatsHelper.getTotalScreenTimeMs(this))

                        "getProductiveTimeMs" ->
                            result.success(UsageStatsHelper.getProductiveTimeMs(this))

                        "getUnproductiveTimeMs" ->
                            result.success(UsageStatsHelper.getUnproductiveTimeMs(this))

                        "openUsageAccessSettings" -> {
                            startActivity(Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS))
                            result.success(null)
                        }

                        else -> result.notImplemented()
                    }
                } catch (e: Exception) {
                    result.error("USAGE_STATS_ERROR", e.message, null)
                }
            }
    }
}
