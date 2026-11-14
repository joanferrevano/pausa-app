import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:pausa_app/core/services/hive_service.dart';
import 'package:pausa_app/features/pausas/models/pausa_config.dart';
import 'package:pausa_app/shared/providers/pausas_provider.dart';

PausaConfig _p(String pkg, {int wait = 15, int max = 5, bool active = true}) =>
    PausaConfig(
      appName: pkg,
      packageName: pkg,
      waitSeconds: wait,
      maxMinutes: max,
      isActive: active,
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tmp;
  late List<List<Map<dynamic, dynamic>>> syncs;

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('pausa_test_');
    await HiveService.initForTest(tmp.path);
    await HiveService.pausasBox.clear();
    syncs = [];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('com.pausa.pausa_app/accessibility'),
      (call) async {
        if (call.method == 'syncPausas') {
          final list = (call.arguments['pausas'] as List)
              .map((e) => Map<dynamic, dynamic>.from(e as Map))
              .toList();
          syncs.add(list);
        }
        return null;
      },
    );
  });

  tearDown(() async {
    await Hive.close();
    await tmp.delete(recursive: true);
  });

  Future<PausasNotifier> notifier() async {
    final n = PausasNotifier();
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);
    syncs.clear();
    return n;
  }

  test('updatePausa sincroniza con el nativo', () async {
    final n = await notifier();
    await n.addPausa(_p('a'));
    syncs.clear();
    await n.updatePausa(0, _p('a', wait: 30));
    expect(syncs, hasLength(1));
    expect(syncs.last.single['waitSeconds'], 30);
  });

  test('deletePausa sincroniza con el nativo', () async {
    final n = await notifier();
    await n.addPausa(_p('a'));
    await n.addPausa(_p('b'));
    syncs.clear();
    await n.deletePausa(0);
    expect(syncs, hasLength(1));
    expect(syncs.last.map((e) => e['packageName']), ['b']);
  });

  test('updatePausa conserva isActive', () async {
    final n = await notifier();
    await n.addPausa(_p('a', active: false));
    await n.updatePausa(0, _p('a', wait: 45)); // el formulario crea isActive=true
    expect(n.state.single.waitSeconds, 45);
    expect(n.state.single.isActive, isFalse);
    expect(syncs.last.single['isActive'], isFalse);
  });

  test('addPausa con paquete existente actualiza y no duplica', () async {
    final n = await notifier();
    await n.addPausa(_p('a', wait: 15, active: false));
    await n.addPausa(_p('a', wait: 60, max: 10));
    expect(n.state, hasLength(1));
    expect(HiveService.pausasBox.length, 1);
    expect(n.state.single.waitSeconds, 60);
    expect(n.state.single.maxMinutes, 10);
    expect(n.state.single.isActive, isFalse);
  });

  test('addPausa con paquetes distintos añade ambas', () async {
    final n = await notifier();
    await n.addPausa(_p('a'));
    await n.addPausa(_p('b'));
    expect(n.state.map((p) => p.packageName), ['a', 'b']);
  });
}
