import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../app/theme.dart';
import 'screen_time_card.dart';
import 'mini_stat_card.dart';
import 'app_usage_card.dart';
import 'motivation_banner.dart';

class DashboardTab extends StatefulWidget {
  const DashboardTab({super.key});

  @override
  State<DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends State<DashboardTab> {
  final List<_FadeSlide> _items = [];

  @override
  void initState() {
    super.initState();
    _items.addAll([
      const _FadeSlide(delay: 0, child: _Header()),
      const _FadeSlide(delay: 80, child: ScreenTimeCard()),
      const _FadeSlide(
        delay: 160,
        child: Row(
          children: [
            MiniStatCard(
              label: 'Pausas activas hoy',
              value: 3,
              unit: 'pausas',
              animationDelay: Duration(milliseconds: 240),
            ),
            SizedBox(width: 12),
            MiniStatCard(
              label: 'Racha actual',
              value: 7,
              unit: 'días',
              animationDelay: Duration(milliseconds: 320),
            ),
          ],
        ),
      ),
      const _FadeSlide(delay: 240, child: AppUsageCard()),
      const _FadeSlide(delay: 320, child: MotivationBanner()),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      itemCount: _items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 16),
      itemBuilder: (_, i) => _items[i],
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Buenos días.',
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
