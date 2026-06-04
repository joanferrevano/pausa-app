import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/hive_service.dart';

class UserState {
  const UserState({this.name = '', this.dailyHours = 3.5});

  final String name;
  final double dailyHours;

  UserState copyWith({String? name, double? dailyHours}) => UserState(
        name: name ?? this.name,
        dailyHours: dailyHours ?? this.dailyHours,
      );
}

final userProvider = StateNotifierProvider<UserNotifier, UserState>(
  (ref) => UserNotifier(),
);

class UserNotifier extends StateNotifier<UserState> {
  UserNotifier() : super(const UserState()) {
    _load();
  }

  static const _keyName = 'user_name';
  static const _keyHours = 'user_daily_hours';

  void _load() {
    final box = HiveService.userBox;
    final name = box.get(_keyName) as String? ?? '';
    final hours = (box.get(_keyHours) as num?)?.toDouble() ?? 3.5;
    state = UserState(name: name, dailyHours: hours);
  }

  Future<void> saveUser(String name, double hours) async {
    final box = HiveService.userBox;
    await box.put(_keyName, name);
    await box.put(_keyHours, hours);
    state = UserState(name: name, dailyHours: hours);
  }
}
