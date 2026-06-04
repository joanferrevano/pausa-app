import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeTop;
  late Animation<double> _fadeButtons;
  late Animation<double> _fadeBottom;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );

    _fadeTop = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.4, curve: Curves.easeOut),
    );
    _fadeButtons = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.3, 0.75, curve: Curves.easeOut),
    );
    _fadeBottom = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.65, 1.0, curve: Curves.easeOut),
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
    return Scaffold(
      backgroundColor: PausaColors.black,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 64),

              // Header
              FadeTransition(
                opacity: _fadeTop,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'pausa',
                      style: GoogleFonts.dmSans(
                        fontSize: 13,
                        color: PausaColors.textMuted,
                        letterSpacing: 0.2,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Empieza a recuperar\ntu tiempo hoy.',
                      style: GoogleFonts.dmSerifDisplay(
                        fontSize: 34,
                        height: 1.2,
                        color: PausaColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Crea tu cuenta para guardar tu progreso\ny acceder a todas las funciones.',
                      style: GoogleFonts.dmSans(
                        fontSize: 14,
                        color: PausaColors.textMuted,
                        height: 1.6,
                      ),
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // Botones de registro
              FadeTransition(
                opacity: _fadeButtons,
                child: Column(
                  children: [
                    // Google
                    _AuthButton(
                      onTap: () => context.goNamed('home'),
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
                      filled: true,
                    ),

                    const SizedBox(height: 12),

                    // Apple
                    _AuthButton(
                      onTap: () => context.goNamed('home'),
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
                      filled: false,
                    ),

                    const SizedBox(height: 12),

                    // Email
                    _AuthButton(
                      onTap: () => context.goNamed('home'),
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
                      filled: false,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Legal
              FadeTransition(
                opacity: _fadeBottom,
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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: filled ? PausaColors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(50),
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

    // Fondo círculo
    paint.color = Colors.white;
    canvas.drawCircle(center, radius, paint);

    // G simplificada
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