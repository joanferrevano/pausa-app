import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/hive_service.dart';
import '../../features/pausas/models/pausa_config.dart';

final pausasProvider =
    StateNotifierProvider<PausasNotifier, List<PausaConfig>>(
  (ref) => PausasNotifier(),
);

class PausasNotifier extends StateNotifier<List<PausaConfig>> {
  PausasNotifier() : super([]) {
    _load();
  }

  void _load() {
    state = HiveService.pausasBox.values.toList();
  }

  Future<void> addPausa(PausaConfig config) async {
    await HiveService.pausasBox.add(config);
    state = HiveService.pausasBox.values.toList();
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

  Future<void> togglePausa(int index, bool value) async {
    final box = HiveService.pausasBox;
    final key = box.keyAt(index);
    final updated = state[index].copyWith(isActive: value);
    await box.put(key, updated);
    state = box.values.toList();
  }
}
