import 'dart:async';
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
      ..color = PausaColors.white
      ..style = PaintingStyle.fill;

    final radius = Radius.circular(size.width * 0.09);

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.width * 0.16, size.height * 0.2,
            size.width * 0.28, size.height * 0.6),
        radius,
      ),
      paint,
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.width * 0.56, size.height * 0.2,
            size.width * 0.28, size.height * 0.6),
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

  int _phraseIndex = 0;
  Timer? _phraseTimer;
  bool _dataReady = false;
  bool _minTimeReached = false;

  late final AnimationController _logoController;
  late final Animation<double> _logoFade;
  late final Animation<Offset> _logoSlide;

  late final AnimationController _progressController;

  @override
  void initState() {
    super.initState();

    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _logoFade = CurvedAnimation(parent: _logoController, curve: Curves.easeOut);
    _logoSlide = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _logoController, curve: Curves.easeOut));
    _logoController.forward();

    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..forward();

    _phraseTimer = Timer.periodic(const Duration(milliseconds: 800), (_) {
      if (mounted) {
        setState(() => _phraseIndex = (_phraseIndex + 1) % _phrases.length);
      }
    });

    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) setState(() => _minTimeReached = true);
      _tryNavigate();
    });

    _preloadData();
  }

  Future<void> _preloadData() async {
    ref.read(usageStatsProvider.notifier).load();
    await ref
        .read(installedAppsProvider.future)
        .catchError((_) => <InstalledApp>[]);
    if (mounted) setState(() => _dataReady = true);
    _tryNavigate();
  }

  void _tryNavigate() {
    if (!_dataReady || !_minTimeReached) return;
    _phraseTimer?.cancel();
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
    _phraseTimer?.cancel();
    _logoController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).padding.bottom;
    return Scaffold(
      backgroundColor: PausaColors.black,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 100),

            SlideTransition(
              position: _logoSlide,
              child: FadeTransition(
                opacity: _logoFade,
                child: Column(
                  children: [
                    SizedBox(
                      width: 64,
                      height: 64,
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
                  ],
                ),
              ),
            ),

            const Spacer(),

            Padding(
              padding: EdgeInsets.fromLTRB(32, 0, 32, 40 + bottom),
              child: Column(
                children: [
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 400),
                    transitionBuilder: (child, animation) =>
                        FadeTransition(opacity: animation, child: child),
                    child: Text(
                      _phrases[_phraseIndex],
                      key: ValueKey(_phraseIndex),
                      textAlign: TextAlign.center,
                      style: GoogleFonts.dmSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: PausaColors.textSecondary,
                        height: 1.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  AnimatedBuilder(
                    animation: _progressController,
                    builder: (_, __) => LinearProgressIndicator(
                      value: _progressController.value,
                      backgroundColor:
                          PausaColors.textMuted.withValues(alpha: 0.2),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        PausaColors.white,
                      ),
                      minHeight: 1,
                      borderRadius: BorderRadius.circular(1),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
