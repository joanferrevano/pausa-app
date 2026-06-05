import 'package:flutter/services.dart';
import '../models/app_usage_info.dart';

class UsageStatsService {
  UsageStatsService._();

  static const _channel = MethodChannel('com.pausa.pausa_app/usage_stats');
  static final Map<String, Uint8List?> _iconCache = {};

  static Future<bool> hasPermission() async {
    try {
      final result = await _channel.invokeMethod<bool>('hasPermission');
      return result ?? false;
    } on PlatformException {
      return false;
    }
  }

  static Future<void> openSettings() async {
    try {
      await _channel.invokeMethod<void>('openUsageAccessSettings');
    } on PlatformException {
      // ignore
    }
  }

  static Future<List<AppUsageInfo>> getTodayUsage() async {
    try {
      final raw = await _channel.invokeMethod<List<Object?>>('getTodayUsage');
      if (raw == null) return [];
      return raw
          .whereType<Map<Object?, Object?>>()
          .map(AppUsageInfo.fromMap)
          .toList();
    } on PlatformException {
      return [];
    }
  }

  static Future<int> getTotalScreenTimeMs() async {
    try {
      final result =
          await _channel.invokeMethod<Object>('getTotalScreenTimeMs');
      return (result as num?)?.toInt() ?? 0;
    } on PlatformException {
      return 0;
    }
  }

  static Future<int> getProductiveTimeMs() async {
    try {
      final result =
          await _channel.invokeMethod<Object>('getProductiveTimeMs');
      return (result as num?)?.toInt() ?? 0;
    } on PlatformException {
      return 0;
    }
  }

  static Future<int> getUnproductiveTimeMs() async {
    try {
      final result =
          await _channel.invokeMethod<Object>('getUnproductiveTimeMs');
      return (result as num?)?.toInt() ?? 0;
    } on PlatformException {
      return 0;
    }
  }

  static Uint8List? getCachedIcon(String packageName) =>
      _iconCache[packageName];

  static Future<Uint8List?> getAppIcon(String packageName) async {
    if (_iconCache.containsKey(packageName)) return _iconCache[packageName];
    try {
      final result = await _channel.invokeMethod<Uint8List>(
        'getAppIcon',
        {'packageName': packageName},
      );
      _iconCache[packageName] = result;
      return result;
    } catch (_) {
      _iconCache[packageName] = null;
      return null;
    }
  }

  static String formatDuration(int ms) {
    final totalSeconds = ms ~/ 1000;
    final h = totalSeconds ~/ 3600;
    final m = (totalSeconds % 3600) ~/ 60;
    if (totalSeconds < 60) return '< 1m';
    if (h > 0) return '${h}h ${m.toString().padLeft(2, '0')}m';
    return '${m}m';
  }
}
