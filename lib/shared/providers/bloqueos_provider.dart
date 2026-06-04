import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/hive_service.dart';
import '../../features/bloqueos/models/bloqueo.dart';

final bloqueosProvider =
    StateNotifierProvider<BloqueosNotifier, List<Bloqueo>>(
  (ref) => BloqueosNotifier(),
);

class BloqueosNotifier extends StateNotifier<List<Bloqueo>> {
  BloqueosNotifier() : super([]) {
    _load();
  }

  void _load() {
    state = HiveService.bloqueosBox.values.toList();
  }

  Future<void> addBloqueo(Bloqueo bloqueo) async {
    await HiveService.bloqueosBox.put(bloqueo.id, bloqueo);
    state = HiveService.bloqueosBox.values.toList();
  }

  Future<void> deleteBloqueo(String id) async {
    await HiveService.bloqueosBox.delete(id);
    state = HiveService.bloqueosBox.values.toList();
  }

  Future<void> activateBloqueo(String id) async {
    final box = HiveService.bloqueosBox;
    final now = DateTime.now();
    for (final b in box.values) {
      final updated = b.copyWith(
        isActive: b.id == id,
        activatedAt: b.id == id ? now : null,
        clearActivatedAt: b.id != id,
      );
      await box.put(b.id, updated);
    }
    state = box.values.toList();
  }

  Future<void> deactivateBloqueo(String id) async {
    final box = HiveService.bloqueosBox;
    final b = box.get(id);
    if (b == null) return;
    await box.put(id, b.copyWith(isActive: false, clearActivatedAt: true));
    state = box.values.toList();
  }
}
