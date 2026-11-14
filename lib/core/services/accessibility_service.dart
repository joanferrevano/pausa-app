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

  /// True solo si el sistema tiene el servicio enlazado y funcionando.
  /// [isEnabled] puede ser true con el servicio caído.
  static Future<bool> isRunning() async {
    try {
      final result = await _channel.invokeMethod<bool>('isAccessibilityRunning');
      return result ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Xiaomi, Redmi o POCO: necesitan "Inicio automático" para que Pausa
  /// vuelva sola después de limpiar las apps recientes.
  static Future<bool> isXiaomi() async {
    try {
      final result = await _channel.invokeMethod<bool>('isXiaomi');
      return result ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Abre la lista de Inicio automático; si no existe, la ficha de la app.
  static Future<void> openAutostartSettings() async {
    try {
      await _channel.invokeMethod('openAutostartSettings');
    } catch (_) {}
  }

  /// Ficha de Pausa en los ajustes del sistema (batería, inicio automático).
  static Future<void> openAppDetails() async {
    try {
      await _channel.invokeMethod('openAppDetails');
    } catch (_) {}
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
