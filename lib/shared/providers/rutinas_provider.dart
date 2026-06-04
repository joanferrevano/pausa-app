import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/hive_service.dart';
import '../../features/rutinas/models/rutina.dart';

final rutinasProvider =
    StateNotifierProvider<RutinasNotifier, List<Rutina>>(
  (ref) => RutinasNotifier(),
);

class RutinasNotifier extends StateNotifier<List<Rutina>> {
  RutinasNotifier() : super([]) {
    _load();
  }

  void _load() {
    state = HiveService.rutinasBox.values.toList();
  }

  Future<void> addRutina(Rutina rutina) async {
    await HiveService.rutinasBox.put(rutina.id, rutina);
    state = HiveService.rutinasBox.values.toList();
  }

  Future<void> updateRutina(Rutina rutina) async {
    await HiveService.rutinasBox.put(rutina.id, rutina);
    state = HiveService.rutinasBox.values.toList();
  }

  Future<void> deleteRutina(String id) async {
    await HiveService.rutinasBox.delete(id);
    state = HiveService.rutinasBox.values.toList();
  }

  Future<void> toggleRutina(String id, bool value) async {
    final box = HiveService.rutinasBox;
    final rutina = box.get(id);
    if (rutina == null) return;
    final updated = rutina.copyWith(isActive: value);
    await box.put(id, updated);
    state = box.values.toList();
  }
}
