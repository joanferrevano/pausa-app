import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/hive_service.dart';
import '../../core/services/accessibility_service.dart';
import '../../features/pausas/models/pausa_config.dart';

final pausasProvider =
    StateNotifierProvider<PausasNotifier, List<PausaConfig>>(
  (ref) => PausasNotifier(),
);

class PausasNotifier extends StateNotifier<List<PausaConfig>> {
  PausasNotifier() : super([]) {
    _loadFromHive();
  }

  Future<void> _loadFromHive() async {
    state = HiveService.pausasBox.values.toList();
    await _syncToNative();
  }

  Future<void> _syncToNative() async {
    final pausasList = state.map((p) => p.toMap()).toList();
    await AccessibilityService.syncPausas(pausasList);
  }

  Future<void> addPausa(PausaConfig config) async {
    await HiveService.pausasBox.add(config);
    state = HiveService.pausasBox.values.toList();
    await _syncToNative();
  }

  Future<void> updatePausa(int index, PausaConfig config) async {
    final box = HiveService.pausasBox;
    final key = box.keyAt(index);
    await box.put(key, config);
    state = box.values.toList();
  }

  Future<void> deletePausa(int index) async {
    final box = HiveService.pausasBox;
    final key = box.keyAt(index);
    await box.delete(key);
    state = box.values.toList();
  }

  Future<void> deletePausaByPackage(String packageName) async {
    final box = HiveService.pausasBox;
    final updated =
        box.values.where((p) => p.packageName != packageName).toList();
    await box.clear();
    for (final p in updated) {
      await box.add(p);
    }
    state = box.values.toList();
    await _syncToNative();
  }

  Future<void> togglePausa(int index, bool value) async {
    final box = HiveService.pausasBox;
    final key = box.keyAt(index);
    final updated = state[index].copyWith(isActive: value);
    await box.put(key, updated);
    state = box.values.toList();
    await _syncToNative();
  }
}
