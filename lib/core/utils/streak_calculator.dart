import 'package:shared_preferences/shared_preferences.dart';

class StreakCalculator {
  StreakCalculator._();

  static const _prefix = 'streak_day_';
  static const _defaultGoalMinutes = 360;

  static Future<void> saveTodayUsage(int totalMinutes) async {
    final prefs = await SharedPreferences.getInstance();
    final today = _dateKey(DateTime.now());
    await prefs.setInt('$_prefix$today', totalMinutes);
  }

  static Future<int> calculateStreak({
    int goalMinutes = _defaultGoalMinutes,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    int streak = 0;
    DateTime day = DateTime.now();

    for (int i = 0; i < 365; i++) {
      final key = '$_prefix${_dateKey(day)}';
      final minutes = prefs.getInt(key);
      if (minutes == null) break;
      if (minutes > goalMinutes) break;
      streak++;
      day = day.subtract(const Duration(days: 1));
    }
    return streak;
  }

  static String _dateKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}
