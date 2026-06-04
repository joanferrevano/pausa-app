import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/app_usage_info.dart';
import '../../core/services/usage_stats_service.dart';

class UsageStatsState {
  const UsageStatsState({
    this.hasPermission = false,
    this.totalScreenTimeMs = 0,
    this.productiveMs = 0,
    this.unproductiveMs = 0,
    this.topApps = const [],
    this.isLoading = true,
  });

  final bool hasPermission;
  final int totalScreenTimeMs;
  final int productiveMs;
  final int unproductiveMs;
  final List<AppUsageInfo> topApps;
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
    bool? isLoading,
  }) =>
      UsageStatsState(
        hasPermission: hasPermission ?? this.hasPermission,
        totalScreenTimeMs: totalScreenTimeMs ?? this.totalScreenTimeMs,
        productiveMs: productiveMs ?? this.productiveMs,
        unproductiveMs: unproductiveMs ?? this.unproductiveMs,
        topApps: topApps ?? this.topApps,
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

  Future<void> load() async {
    state = state.copyWith(isLoading: true);
    try {
      final permitted = await UsageStatsService.hasPermission();
      if (!permitted) {
        state = state.copyWith(hasPermission: false, isLoading: false);
        return;
      }
      final results = await Future.wait([
        UsageStatsService.getTotalScreenTimeMs(),
        UsageStatsService.getProductiveTimeMs(),
        UsageStatsService.getUnproductiveTimeMs(),
        UsageStatsService.getTodayUsage(),
      ]);
      state = UsageStatsState(
        hasPermission: true,
        totalScreenTimeMs: results[0] as int,
        productiveMs: results[1] as int,
        unproductiveMs: results[2] as int,
        topApps: results[3] as List<AppUsageInfo>,
        isLoading: false,
      );
    } catch (_) {
      state = state.copyWith(isLoading: false);
    }
  }
}
