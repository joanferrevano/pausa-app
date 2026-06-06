import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../app/theme.dart';
import '../../../shared/providers/usage_stats_provider.dart';
import '../../../shared/providers/pausas_provider.dart';
import 'screen_time_card.dart';
import 'mini_stat_card.dart';
import 'app_usage_card.dart';
import 'motivation_banner.dart';
import 'permission_banner.dart';

class DashboardTab extends ConsumerStatefulWidget {
  const DashboardTab({super.key});

  @override
  ConsumerState<DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends ConsumerState<DashboardTab>
    with WidgetsBindingObserver {
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _startTimer();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.read(usageStatsProvider.notifier).load();
    }
  }

  void _startTimer() {
    _refreshTimer = Timer.periodic(const Duration(seconds: 60), (_) {
      if (mounted) ref.read(usageStatsProvider.notifier).load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final usage = ref.watch(usageStatsProvider);
    final activePausas =
        ref.watch(pausasProvider).where((p) => p.isActive).length;

    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 96),
      children: [
        const _FadeSlide(
          delay: 0,
          child: _Header(),
        ),
        const SizedBox(height: 16),
        if (!usage.hasPermission && !usage.isLoading) ...[
          const _FadeSlide(delay: 40, child: PermissionBanner()),
          const SizedBox(height: 16),
        ],
        _FadeSlide(
          delay: 80,
          child: ScreenTimeCard(
            totalMs: usage.totalScreenTimeMs,
            productiveMs: usage.productiveMs,
            unproductiveMs: usage.unproductiveMs,
          ),
        ),
        const SizedBox(height: 16),
        _FadeSlide(
          delay: 160,
          child: Row(
            children: [
              MiniStatCard(
                label: 'Pausas activas hoy',
                value: activePausas,
                unit: 'pausas',
                animationDelay: const Duration(milliseconds: 240),
              ),
              const SizedBox(width: 12),
              MiniStatCard(
                label: 'Racha actual',
                value: usage.streak,
                unit: usage.streak == 1 ? 'día' : 'días',
                animationDelay: const Duration(milliseconds: 320),
                showFireWhenPositive: true,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _FadeSlide(
          delay: 240,
          child: AppUsageCard(apps: usage.topApps),
        ),
        const SizedBox(height: 16),
        _FadeSlide(
          delay: 320,
          child: MotivationBanner(
            streak: usage.streak,
            weeklyRecovered: usage.weeklyRecoveredFormatted,
          ),
        ),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour >= 6 && hour < 14) return 'Buenos días.';
    if (hour >= 14 && hour < 21) return 'Buenas tardes.';
    return 'Buenas noches.';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            _greeting,
            style: GoogleFonts.dmSerifDisplay(
              fontSize: 28,
              color: PausaColors.white,
              height: 1.2,
            ),
          ),
          GestureDetector(
            onTap: () {},
            child: const Icon(
              Icons.settings_outlined,
              color: PausaColors.textSecondary,
              size: 22,
            ),
          ),
        ],
      ),
    );
  }
}

class _FadeSlide extends StatefulWidget {
  const _FadeSlide({required this.delay, required this.child});

  final int delay;
  final Widget child;

  @override
  State<_FadeSlide> createState() => _FadeSlideState();
}

class _FadeSlideState extends State<_FadeSlide>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _opacity;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _opacity = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.04),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: SlideTransition(position: _slide, child: widget.child),
    );
  }
}
