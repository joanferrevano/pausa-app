import 'package:hive_flutter/hive_flutter.dart';
import '../../features/pausas/models/pausa_config.dart';
import '../../features/rutinas/models/rutina.dart';
import '../../features/bloqueos/models/bloqueo.dart';
import '../utils/hive_constants.dart';

class HiveService {
  HiveService._();

  static late Box<PausaConfig> _pausasBox;
  static late Box<Rutina> _rutinasBox;
  static late Box<Bloqueo> _bloqueosBox;
  static late Box<dynamic> _userBox;

  static Box<PausaConfig> get pausasBox => _pausasBox;
  static Box<Rutina> get rutinasBox => _rutinasBox;
  static Box<Bloqueo> get bloqueosBox => _bloqueosBox;
  static Box<dynamic> get userBox => _userBox;

  static Future<void> init() async {
    await Hive.initFlutter();

    Hive.registerAdapter(PausaConfigAdapter());
    Hive.registerAdapter(RutinaAdapter());
    Hive.registerAdapter(BloqueoAdapter());

    _pausasBox = await Hive.openBox<PausaConfig>(HiveConstants.pausasBox);
    _rutinasBox = await Hive.openBox<Rutina>(HiveConstants.rutinasBox);
    _bloqueosBox = await Hive.openBox<Bloqueo>(HiveConstants.bloqueosBox);
    _userBox = await Hive.openBox<dynamic>(HiveConstants.userBox);
  }
}
