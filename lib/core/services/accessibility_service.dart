import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class AccessibilityService {
  static const _channel = MethodChannel('com.pausa.pausa_app/accessibility');

  static Future<bool> isEnabled() async {
    try {
      final result = await _channel.invokeMethod<bool>('isAccessibilityEnabled');
      return result ?? false;
    } catch (_) {
      return false;
    }
  }

  static Future<void> openSettings() async {
    try {
      await _channel.invokeMethod('openAccessibilitySettings');
    } catch (_) {}
  }

  static Future<bool> isInDailyCooldown(String packageName) async {
    try {
      final result = await _channel.invokeMethod<bool>(
        'isInDailyCooldown',
        {'packageName': packageName},
      );
      return result ?? false;
    } catch (_) {
      return false;
    }
  }

  static Future<void> resetDailyCooldown(String packageName) async {
    try {
      await _channel.invokeMethod('resetDailyCooldown', {'packageName': packageName});
    } catch (_) {}
  }

  static Future<void> syncPausas(List<Map<String, dynamic>> pausas) async {
    try {
      await _channel.invokeMethod('syncPausas', {'pausas': pausas});
      debugPrint('✅ Pausas synced to native: ${pausas.length} items');
      for (final p in pausas) {
        debugPrint('  → ${p['packageName']} active:${p['isActive']}');
      }
    } catch (e) {
      debugPrint('❌ Sync failed: $e');
    }
  }
}
