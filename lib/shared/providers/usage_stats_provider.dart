import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/app_usage_info.dart';
import '../../core/services/usage_stats_service.dart';
import '../../core/utils/streak_calculator.dart';

class UsageStatsState {
  const UsageStatsState({
    this.hasPermission = false,
    this.totalScreenTimeMs = 0,
    this.productiveMs = 0,
    this.unproductiveMs = 0,
    this.topApps = const [],
    this.streak = 0,
    this.weeklyRecoveredFormatted = '0m',
    this.isLoading = true,
  });

  final bool hasPermission;
  final int totalScreenTimeMs;
  final int productiveMs;
  final int unproductiveMs;
  final List<AppUsageInfo> topApps;
  final int streak;
  final String weeklyRecoveredFormatted;
  final bool isLoading;

  double get productiveFraction =>
      totalScreenTimeMs == 0 ? 0 : productiveMs / totalScreenTimeMs;

  double get unproductiveFraction =>
      totalScreenTimeMs == 0 ? 0 : unproductiveMs / totalScreenTimeMs;

  UsageStatsState copyWith({
    bool? hasPermission,
    int? totalScreenTimeMs,
    int? productiveMs,
    int? unproductiveMs,
    List<AppUsageInfo>? topApps,
    int? streak,
    String? weeklyRecoveredFormatted,
    bool? isLoading,
  }) =>
      UsageStatsState(
        hasPermission: hasPermission ?? this.hasPermission,
        totalScreenTimeMs: totalScreenTimeMs ?? this.totalScreenTimeMs,
        productiveMs: productiveMs ?? this.productiveMs,
        unproductiveMs: unproductiveMs ?? this.unproductiveMs,
        topApps: topApps ?? this.topApps,
        streak: streak ?? this.streak,
        weeklyRecoveredFormatted:
            weeklyRecoveredFormatted ?? this.weeklyRecoveredFormatted,
        isLoading: isLoading ?? this.isLoading,
      );
}

final usageStatsProvider =
    StateNotifierProvider<UsageStatsNotifier, UsageStatsState>(
  (ref) => UsageStatsNotifier(),
);

class UsageStatsNotifier extends StateNotifier<UsageStatsState> {
  UsageStatsNotifier() : super(const UsageStatsState()) {
    load();
  }

  bool _permissionGranted = false;

  Future<bool> _checkPermission() async {
    final first = await UsageStatsService.hasPermission();
    if (first) return true;
    await Future.delayed(const Duration(milliseconds: 500));
    return UsageStatsService.hasPermission();
  }

  Future<void> load() async {
    state = state.copyWith(
      hasPermission: _permissionGranted,
      isLoading: true,
    );

    try {
      final permitted = await _checkPermission();
      if (permitted) _permissionGranted = true;

      if (!_permissionGranted) {
        state = state.copyWith(hasPermission: false, isLoading: false);
        return;
      }

      final results = await Future.wait([
        UsageStatsService.getTotalScreenTimeMs(),
        UsageStatsService.getProductiveTimeMs(),
        UsageStatsService.getUnproductiveTimeMs(),
        UsageStatsService.getTodayUsage(),
      ]);

      final totalMs = results[0] as int;
      final totalMinutes = totalMs ~/ 60000;

      await StreakCalculator.saveTodayUsage(totalMinutes);

      final streak = await StreakCalculator.calculateStreak();
      final weeklyRecoveredFormatted =
          await StreakCalculator.computeWeeklyRecoveredFormatted();

      final apps = results[3] as List<AppUsageInfo>;
      await Future.wait(
        apps.map((a) => UsageStatsService.getAppIcon(a.packageName)),
        eagerError: false,
      );

      state = UsageStatsState(
        hasPermission: true,
        totalScreenTimeMs: totalMs,
        productiveMs: results[1] as int,
        unproductiveMs: results[2] as int,
        topApps: apps,
        streak: streak,
        weeklyRecoveredFormatted: weeklyRecoveredFormatted,
        isLoading: false,
      );
    } catch (_) {
      state = state.copyWith(isLoading: false);
    }
  }
}
