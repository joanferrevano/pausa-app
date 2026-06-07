import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/accessibility_service.dart';

class AccessibilityState {
  final bool isEnabled;
  final bool isLoading;

  const AccessibilityState({
    this.isEnabled = false,
    this.isLoading = true,
  });
}

class AccessibilityNotifier extends StateNotifier<AccessibilityState> {
  AccessibilityNotifier() : super(const AccessibilityState()) {
    _check();
  }

  Future<void> _check() async {
    final enabled = await AccessibilityService.isEnabled();
    state = AccessibilityState(isEnabled: enabled, isLoading: false);
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
