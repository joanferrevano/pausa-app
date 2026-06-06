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

  static Future<bool> hasAnyData() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getKeys().any((k) => k.startsWith(_prefix));
  }

  static Future<int> calculateStreak({
    int goalMinutes = _defaultGoalMinutes,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    if (!prefs.getKeys().any((k) => k.startsWith(_prefix))) return 0;

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

  static Future<String> computeWeeklyRecoveredFormatted({
    int goalMinutes = _defaultGoalMinutes,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    if (!prefs.getKeys().any((k) => k.startsWith(_prefix))) return '0m';

    int totalMinutes = 0;
    final now = DateTime.now();
    for (int i = 0; i < 7; i++) {
      final day = now.subtract(Duration(days: i));
      final key = '$_prefix${_dateKey(day)}';
      final minutes = prefs.getInt(key);
      if (minutes != null && minutes < goalMinutes) {
        totalMinutes += goalMinutes - minutes;
      }
    }

    final h = totalMinutes ~/ 60;
    final m = totalMinutes % 60;
    if (h > 0 && m > 0) return '${h}h ${m}m';
    if (h > 0) return '${h}h';
    return '${m}m';
  }

  static String _dateKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}
