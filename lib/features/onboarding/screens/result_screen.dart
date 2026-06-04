import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme.dart';

class ResultScreen extends StatefulWidget {
  final Map<String, dynamic>? extra;
  const ResultScreen({super.key, this.extra});

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeTop;
  late Animation<double> _fadeCards;
  late Animation<double> _fadeBottom;
  late Animation<double> _ringAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    _fadeTop = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.4, curve: Curves.easeOut),
    );
    _ringAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.2, 0.7, curve: Curves.easeOut),
    );
    _fadeCards = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.4, 0.8, curve: Curves.easeOut),
    );
    _fadeBottom = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.7, 1.0, curve: Curves.easeOut),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final nombre = widget.extra?['nombre'] as String? ?? '';
    final diasAno = widget.extra?['diasAno'] as int? ?? 0;
    final aniosVida = widget.extra?['aniosVida'] as int? ?? 0;
    final aniosRecuperables = widget.extra?['aniosRecuperables'] as int? ?? 0;

    return Scaffold(
      backgroundColor: PausaColors.black,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 48),

              // Header
              FadeTransition(
                opacity: _fadeTop,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      nombre.isNotEmpty ? 'Hola, $nombre.' : 'Tu resultado.',
                      style: GoogleFonts.dmSans(
                        fontSize: 13,
                        color: PausaColors.textMuted,
                        letterSpacing: 0.08,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Este es el tiempo\nque estás perdiendo.',
                      style: GoogleFonts.dmSerifDisplay(
                        fontSize: 30,
                        height: 1.2,
                        color: PausaColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 40),

              // Anillo central
              FadeTransition(
                opacity: _ringAnimation,
                child: Center(
                  child: SizedBox(
                    width: 160,
                    height: 160,
                    child: AnimatedBuilder(
                      animation: _ringAnimation,
                      builder: (context, _) {
                        return CustomPaint(
                          painter: _ResultRingPainter(_ringAnimation.value),
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  '$aniosVida',
                                  style: GoogleFonts.dmSerifDisplay(
                                    fontSize: 48,
                                    height: 1.0,
                                    color: PausaColors.red,
                                  ),
                                ),
                                Text(
                                  'años',
                                  style: GoogleFonts.dmSans(
                                    fontSize: 13,
                                    color: PausaColors.textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // Cards stats
              FadeTransition(
                opacity: _fadeCards,
                child: Column(
                  children: [
                    _StatCard(
                      label: 'Este año perderás',
                      value: '$diasAno días',
                      danger: true,
                    ),
                    const SizedBox(height: 10),
                    _StatCard(
                      label: 'A lo largo de tu vida',
                      value: '$aniosVida años',
                      danger: true,
                    ),
                    const SizedBox(height: 10),
                    _StatCard(
                      label: 'Podrías recuperar',
                      value: '+$aniosRecuperables años',
                      danger: false,
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // CTA
              FadeTransition(
                opacity: _fadeBottom,
                child: GestureDetector(
                  onTap: () => context.goNamed('upsell'),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    decoration: BoxDecoration(
                      color: PausaColors.white,
                      borderRadius: BorderRadius.circular(50),
                    ),
                    child: Text(
                      'Quiero recuperar esos años',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.dmSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: PausaColors.black,
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final bool danger;

  const _StatCard({
    required this.label,
    required this.value,
    required this.danger,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: PausaColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: PausaColors.border, width: 0.5),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.dmSans(
              fontSize: 13,
              color: PausaColors.textMuted,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.dmSerifDisplay(
              fontSize: 20,
              color: danger ? PausaColors.red : PausaColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _ResultRingPainter extends CustomPainter {
  final double progress;
  _ResultRingPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 10;

    final trackPaint = Paint()
      ..color = PausaColors.surface
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6;

    canvas.drawCircle(center, radius, trackPaint);

    final arcPaint = Paint()
      ..color = PausaColors.red
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -1.5708,
      progress * 2 * 3.14159 * 0.75,
      false,
      arcPaint,
    );
  }

  @override
  bool shouldRepaint(_ResultRingPainter old) => old.progress != progress;
}