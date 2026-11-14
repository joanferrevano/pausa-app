import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/accessibility_service.dart';

class AccessibilityState {
  final bool isEnabled;
  final bool isRunning;
  final bool isLoading;

  const AccessibilityState({
    this.isEnabled = false,
    this.isRunning = false,
    this.isLoading = true,
  });

  /// Activado en Ajustes pero sin funcionar: el sistema no ha vuelto a enlazar
  /// el servicio (pasa en Xiaomi tras "cerrar todo") y las pausas no saltan.
  bool get isStopped => !isLoading && isEnabled && !isRunning;
}

class AccessibilityNotifier extends StateNotifier<AccessibilityState> {
  AccessibilityNotifier({this.recheckDelay = const Duration(seconds: 3)})
      : super(const AccessibilityState()) {
    _check();
  }

  /// Al abrir la app en frío el sistema puede tardar un momento en enlazar el
  /// servicio; se vuelve a mirar antes de darlo por caído.
  final Duration recheckDelay;

  Future<void> _check() async {
    final enabled = await AccessibilityService.isEnabled();
    var running = enabled && await AccessibilityService.isRunning();
    if (enabled && !running) {
      await Future<void>.delayed(recheckDelay);
      if (!mounted) return;
      running = await AccessibilityService.isRunning();
    }
    if (!mounted) return;
    state = AccessibilityState(
      isEnabled: enabled,
      isRunning: running,
      isLoading: false,
    );
  }

  Future<void> refresh() => _check();

  Future<void> openSettings() async {
    await AccessibilityService.openSettings();
  }
}

final accessibilityProvider =
    StateNotifierProvider<AccessibilityNotifier, AccessibilityState>(
  (ref) => AccessibilityNotifier(),
);
