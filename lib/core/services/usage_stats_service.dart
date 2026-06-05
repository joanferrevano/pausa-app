import 'package:flutter/foundation.dart';
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

  static Future<List<Map<String, String>>> getInstalledApps() async {
    try {
      final result = await _channel.invokeMethod<List>('getInstalledApps');
      if (result == null) return [];
      return result.map((e) {
        final map = Map<String, dynamic>.from(e as Map);
        return {
          'packageName': map['packageName'] as String,
          'appName': map['appName'] as String,
        };
      }).toList();
    } catch (_) {
      return [];
    }
  }

  static Uint8List? getCachedIcon(String packageName) =>
      _iconCache[packageName];

  static Future<Uint8List?> getAppIcon(String packageName) async {
    if (_iconCache.containsKey(packageName)) return _iconCache[packageName];
    try {
      final dynamic raw = await _channel.invokeMethod(
        'getAppIcon',
        {'packageName': packageName},
      );

      Uint8List? bytes;
      if (raw == null) {
        bytes = null;
      } else if (raw is Uint8List) {
        bytes = raw;
      } else if (raw is List<dynamic>) {
        bytes = Uint8List.fromList(
            raw.map((e) => (e as num).toInt()).toList());
      } else if (raw is List<int>) {
        bytes = Uint8List.fromList(raw);
      }

      _iconCache[packageName] = bytes;
      return bytes;
    } catch (e) {
      debugPrint('getAppIcon error for $packageName: $e');
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
