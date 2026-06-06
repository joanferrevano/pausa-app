import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app/router.dart';
import 'app/theme.dart';
import 'core/services/hive_service.dart';
import 'shared/providers/installed_apps_provider.dart';
import 'shared/providers/usage_stats_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await HiveService.init();

  final prefs = await SharedPreferences.getInstance();
  final onboardingDone = prefs.getBool('onboarding_done') ?? false;

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFF0A0A0A),
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  runApp(
    ProviderScope(
      child: PausaApp(onboardingDone: onboardingDone),
    ),
  );
}

class PausaApp extends ConsumerWidget {
  final bool onboardingDone;
  const PausaApp({super.key, required this.onboardingDone});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(installedAppsProvider.future).ignore();
      ref.read(usageStatsProvider.notifier).load();
    });

    return MaterialApp.router(
      title: 'Pausa',
      debugShowCheckedModeBanner: false,
      theme: PausaTheme.dark,
      routerConfig: PausaRouter.router(onboardingDone: onboardingDone),
    );
  }
}
