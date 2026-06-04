import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme.dart';
import '../../../app/widgets/fade_slide_in.dart';
import '../../../app/widgets/pressable_feedback.dart';

class RegisterScreen extends StatelessWidget {
  const RegisterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PausaColors.black,
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 64),

              // Logo wordmark — PAUSA uppercase centered
              FadeSlideIn(
                delay: const Duration(milliseconds: 0),
                duration: const Duration(milliseconds: 500),
                child: Align(
                  alignment: Alignment.center,
                  child: Text(
                    'PAUSA',
                    style: GoogleFonts.dmSans(
                      fontSize: 13,
                      color: PausaColors.textMuted,
                      letterSpacing: 0.32,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              FadeSlideIn(
                delay: const Duration(milliseconds: 80),
                duration: const Duration(milliseconds: 500),
                child: Text(
                  'Empieza a recuperar\ntu tiempo hoy.',
                  style: GoogleFonts.dmSerifDisplay(
                    fontSize: 34,
                    height: 1.2,
                    color: PausaColors.textPrimary,
                  ),
                ),
              ),

              const SizedBox(height: 16),

              FadeSlideIn(
                delay: const Duration(milliseconds: 160),
                duration: const Duration(milliseconds: 400),
                child: Text(
                  'Crea tu cuenta para guardar tu progreso\ny acceder a todas las funciones.',
                  style: GoogleFonts.dmSans(
                    fontSize: 14,
                    color: PausaColors.textMuted,
                    height: 1.6,
                  ),
                ),
              ),

              const Spacer(),

              // Auth buttons — staggered
              FadeSlideIn(
                delay: const Duration(milliseconds: 320),
                duration: const Duration(milliseconds: 400),
                child: _AuthButton(
                  onTap: () => context.goNamed('home'),
                  filled: true,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _GoogleIcon(),
                      const SizedBox(width: 12),
                      Text(
                        'Continuar con Google',
                        style: GoogleFonts.dmSans(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: PausaColors.black,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 10),

              FadeSlideIn(
                delay: const Duration(milliseconds: 400),
                duration: const Duration(milliseconds: 400),
                child: _AuthButton(
                  onTap: () => context.goNamed('home'),
                  filled: false,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.apple_rounded,
                        color: PausaColors.textPrimary,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Continuar con Apple',
                        style: GoogleFonts.dmSans(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: PausaColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 10),

              FadeSlideIn(
                delay: const Duration(milliseconds: 480),
                duration: const Duration(milliseconds: 400),
                child: _AuthButton(
                  onTap: () => context.goNamed('home'),
                  filled: false,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.mail_outline_rounded,
                        color: PausaColors.textPrimary,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Continuar con email',
                        style: GoogleFonts.dmSans(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: PausaColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Legal — centered
              FadeSlideIn(
                delay: const Duration(milliseconds: 560),
                duration: const Duration(milliseconds: 400),
                child: SizedBox(
                  width: double.infinity,
                  child: Text(
                    'Al continuar aceptas nuestros Términos de uso\ny Política de privacidad.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.dmSans(
                      fontSize: 11,
                      color: PausaColors.textMuted,
                      height: 1.6,
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

class _AuthButton extends StatelessWidget {
  final VoidCallback onTap;
  final Widget child;
  final bool filled;

  const _AuthButton({
    required this.onTap,
    required this.child,
    required this.filled,
  });

  @override
  Widget build(BuildContext context) {
    return PressableFeedback(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: filled ? PausaColors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: filled ? Colors.transparent : PausaColors.border,
            width: 0.5,
          ),
        ),
        child: child,
      ),
    );
  }
}

class _GoogleIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 20,
      height: 20,
      child: CustomPaint(painter: _GooglePainter()),
    );
  }
}

class _GooglePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    paint.color = Colors.white;
    canvas.drawCircle(center, radius, paint);

    final textPainter = TextPainter(
      text: const TextSpan(
        text: 'G',
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: Color(0xFF4285F4),
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        center.dx - textPainter.width / 2,
        center.dy - textPainter.height / 2,
      ),
    );
  }

  @override
  bool shouldRepaint(_GooglePainter old) => false;
}