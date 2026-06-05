import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/installed_app.dart';
import '../../core/services/usage_stats_service.dart';

final installedAppsProvider =
    AsyncNotifierProvider<InstalledAppsNotifier, List<InstalledApp>>(
  InstalledAppsNotifier.new,
);

class InstalledAppsNotifier extends AsyncNotifier<List<InstalledApp>> {
  @override
  Future<List<InstalledApp>> build() async {
    final raw = await UsageStatsService.getInstalledApps();
    final apps = raw
        .map((m) => InstalledApp(
              packageName: m['packageName']!,
              appName: m['appName']!,
            ))
        .toList();

    // Warm icon cache for first 20 apps so picker shows icons immediately
    final first20 = apps.take(20).toList();
    await Future.wait(
      first20.map((app) => UsageStatsService.getAppIcon(app.packageName)),
      eagerError: false,
    );

    return apps;
  }
}
