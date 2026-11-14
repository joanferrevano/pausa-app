import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pausa_app/shared/providers/accessibility_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('com.pausa.pausa_app/accessibility');

  void mockNative({required bool enabled, required bool running}) {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      switch (call.method) {
        case 'isAccessibilityEnabled':
          return enabled;
        case 'isAccessibilityRunning':
          return running;
      }
      return null;
    });
  }

  Future<AccessibilityState> stateFor({
    required bool enabled,
    required bool running,
  }) async {
    mockNative(enabled: enabled, running: running);
    final notifier = AccessibilityNotifier(recheckDelay: Duration.zero);
    addTearDown(notifier.dispose);
    await notifier.refresh();
    return notifier.state;
  }

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('activado pero sin funcionar: el servicio se da por detenido', () async {
    final state = await stateFor(enabled: true, running: false);
    expect(state.isEnabled, isTrue);
    expect(state.isRunning, isFalse);
    expect(state.isStopped, isTrue);
  });

  test('activado y funcionando: no hay aviso', () async {
    final state = await stateFor(enabled: true, running: true);
    expect(state.isStopped, isFalse);
  });

  test('sin activar: no es un servicio detenido, es un permiso que falta',
      () async {
    final state = await stateFor(enabled: false, running: false);
    expect(state.isEnabled, isFalse);
    expect(state.isStopped, isFalse);
  });
}
