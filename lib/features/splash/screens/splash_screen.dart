import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../app/theme.dart';
import '../../../core/models/installed_app.dart';
import '../../../shared/providers/installed_apps_provider.dart';
import '../../../shared/providers/usage_stats_provider.dart';

class _PausaLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFF0F0F0)
      ..style = PaintingStyle.fill;

    final barWidth = size.width * 0.28;
    final barHeight = size.height * 0.65;
    final barTop = size.height * 0.175;
    final radius = Radius.circular(barWidth * 0.4);

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.width * 0.12, barTop, barWidth, barHeight),
        radius,
      ),
      paint,
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.width * 0.60, barTop, barWidth, barHeight),
        radius,
      ),
      paint,
    );
  }

  @override
  bool shouldRepaint(_PausaLogoPainter old) => false;
}

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with TickerProviderStateMixin {
  static const List<String> _phrases = [
    'Recupera tu tiempo.',
    'El scroll no para. Tú sí puedes.',
    'Tu atención vale más que cualquier like.',
    'Menos pantalla, más vida.',
    'Cada minuto cuenta.',
    'Tú decides cuándo parar.',
    'La dopamina digital tiene un precio.',
    'Hoy es un buen día para pausar.',
  ];

  late final AnimationController _entranceController;
  late final AnimationController _progressController;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;
  late final Animation<double> _progressAnimation;
  late final String _phrase;
  bool _dataReady = false;
  bool _minTimeReached = false;

  @override
  void initState() {
    super.initState();

    _phrase = _phrases[Random().nextInt(_phrases.length)];

    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _entranceController,
      curve: Curves.easeOut,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.03),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _entranceController,
      curve: Curves.easeOut,
    ));

    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
    _progressAnimation = CurvedAnimation(
      parent: _progressController,
      curve: Curves.easeInOut,
    );

    _entranceController.forward();
    _progressController.forward();

    Future.delayed(const Duration(milliseconds: 2000), () {
      if (mounted) {
        setState(() => _minTimeReached = true);
        _tryNavigate();
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _preloadData();
    });
  }

  Future<void> _preloadData() async {
    try {
      ref.read(usageStatsProvider.notifier).load();
      await ref
          .read(installedAppsProvider.future)
          .catchError((_) => <InstalledApp>[]);
    } catch (_) {}
    if (mounted) {
      setState(() => _dataReady = true);
      _tryNavigate();
    }
  }

  void _tryNavigate() {
    if (!_dataReady || !_minTimeReached) return;
    _navigateNext();
  }

  Future<void> _navigateNext() async {
    final prefs = await SharedPreferences.getInstance();
    final onboardingDone = prefs.getBool('onboarding_done') ?? false;
    if (mounted) {
      context.goNamed(onboardingDone ? 'home' : 'hook');
    }
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).padding.bottom;
    return Scaffold(
      backgroundColor: PausaColors.black,
      body: SafeArea(
        child: SlideTransition(
          position: _slideAnimation,
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Column(
              children: [
                const Spacer(flex: 2),

                SizedBox(
                  width: 120,
                  height: 120,
                  child: CustomPaint(painter: _PausaLogoPainter()),
                ),
                const SizedBox(height: 16),
                Text(
                  'pausa',
                  style: GoogleFonts.dmSans(
                    fontSize: 18,
                    fontWeight: FontWeight.w300,
                    letterSpacing: 0.2,
                    color: PausaColors.textMuted,
                  ),
                ),

                const Spacer(flex: 3),

                Padding(
                  padding: EdgeInsets.fromLTRB(32, 0, 32, bottom + 40),
                  child: Column(
                    children: [
                      Text(
                        _phrase,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.dmSerifDisplay(
                          fontSize: 22,
                          fontStyle: FontStyle.italic,
                          color: PausaColors.textSecondary,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 20),
                      AnimatedBuilder(
                        animation: _progressAnimation,
                        builder: (_, __) => LinearProgressIndicator(
                          value: _progressAnimation.value,
                          backgroundColor: PausaColors.border,
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            PausaColors.white,
                          ),
                          minHeight: 1.5,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
