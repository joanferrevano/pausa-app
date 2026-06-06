import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme.dart';
import '../../../shared/providers/usage_stats_provider.dart';

class CalculatingScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic>? extra;
  const CalculatingScreen({super.key, this.extra});

  @override
  ConsumerState<CalculatingScreen> createState() => _CalculatingScreenState();
}

class _CalculatingScreenState extends ConsumerState<CalculatingScreen>
    with TickerProviderStateMixin {
  late AnimationController _spinController;
  late AnimationController _sweepController;
  late AnimationController _textController;
  late Animation<double> _fadeText;

  int _messageIndex = 0;
  final List<String> _messages = [
    'Analizando tus hábitos...',
    'Calculando días perdidos...',
    'Proyectando años de vida...',
    'Preparando tu resultado...',
  ];

  @override
  void initState() {
    super.initState();

    _spinController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat();

    _sweepController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);

    _textController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _fadeText = CurvedAnimation(parent: _textController, curve: Curves.easeOut);

    _textController.forward();

    Future.delayed(const Duration(milliseconds: 750), _nextMessage);
    Future.delayed(const Duration(milliseconds: 3500), _goToResult);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(usageStatsProvider.notifier).load();
    });
  }

  void _nextMessage() {
    if (!mounted) return;
    if (_messageIndex < _messages.length - 1) {
      _textController.reverse().then((_) {
        if (!mounted) return;
        setState(() => _messageIndex++);
        _textController.forward();
        Future.delayed(const Duration(milliseconds: 750), _nextMessage);
      });
    }
  }

  void _goToResult() {
    if (!mounted) return;
    final nombre = widget.extra?['nombre'] as String? ?? '';
    final horas = widget.extra?['horas'] as double? ?? 3.5;

    final diasAno = (horas * 365 / 24).round();
    final aniosVida = (horas * 50 / 24).round();
    final aniosRecuperables = (aniosVida * 0.45).round();

    context.goNamed('resultado', extra: {
      'nombre': nombre,
      'horas': horas,
      'diasAno': diasAno,
      'aniosVida': aniosVida,
      'aniosRecuperables': aniosRecuperables,
    });
  }

  @override
  void dispose() {
    _spinController.dispose();
    _sweepController.dispose();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PausaColors.black,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 96,
                height: 96,
                child: AnimatedBuilder(
                  animation: Listenable.merge([_spinController, _sweepController]),
                  builder: (context, _) {
                    return CustomPaint(
                      painter: _SpinnerPainter(
                        rotation: _spinController.value,
                        sweepFactor: _sweepController.value,
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 48),

              Text(
                'PAUSA',
                style: GoogleFonts.dmSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.32,
                  color: PausaColors.textMuted,
                ),
              ),

              const SizedBox(height: 16),

              FadeTransition(
                opacity: _fadeText,
                child: Text(
                  _messages[_messageIndex],
                  style: GoogleFonts.dmSans(
                    fontSize: 14,
                    color: PausaColors.textSecondary,
                    letterSpacing: 0.04,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SpinnerPainter extends CustomPainter {
  final double rotation;
  final double sweepFactor;

  _SpinnerPainter({required this.rotation, required this.sweepFactor});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 4;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final trackPaint = Paint()
      ..color = PausaColors.border
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawCircle(center, radius, trackPaint);

    const minSweep = 40 * pi / 180;
    const maxSweep = 260 * pi / 180;
    final sweep = minSweep + (maxSweep - minSweep) * sweepFactor;

    final startAngle = rotation * 2 * pi - pi / 2;

    final arcPaint = Paint()
      ..color = PausaColors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(rect, startAngle, sweep, false, arcPaint);
  }

  @override
  bool shouldRepaint(_SpinnerPainter old) =>
      old.rotation != rotation || old.sweepFactor != sweepFactor;
}
