import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme.dart';

class DopamineScreen extends StatefulWidget {
  const DopamineScreen({super.key});

  @override
  State<DopamineScreen> createState() => _DopamineScreenState();
}

class _DopamineScreenState extends State<DopamineScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeIcon;
  late Animation<double> _fadeQuote;
  late Animation<double> _fadeBottom;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    _fadeIcon = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.35, curve: Curves.easeOut),
    );
    _fadeQuote = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.25, 0.7, curve: Curves.easeOut),
    );
    _fadeBottom = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.6, 1.0, curve: Curves.easeOut),
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

              // Icono
              FadeTransition(
                opacity: _fadeIcon,
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: PausaColors.redMuted,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.bolt_rounded,
                    color: PausaColors.red,
                    size: 26,
                  ),
                ),
              ),

              const SizedBox(height: 40),

              // Quote
              FadeTransition(
                opacity: _fadeQuote,
                child: RichText(
                  text: TextSpan(
                    style: GoogleFonts.dmSerifDisplay(
                      fontSize: 28,
                      height: 1.35,
                      color: PausaColors.textPrimary,
                    ),
                    children: const [
                      TextSpan(
                        text: 'La dopamina que libera\nscrollear en TikTok es\nsimilar a la de la ',
                      ),
                      TextSpan(
                        text: 'cocaína.',
                        style: TextStyle(
                          fontStyle: FontStyle.italic,
                          color: PausaColors.red,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              FadeTransition(
                opacity: _fadeQuote,
                child: Text(
                  'Te estás drogando digitalmente\ncada vez que abres el móvil.',
                  style: GoogleFonts.dmSans(
                    fontSize: 15,
                    color: PausaColors.textSecondary,
                    height: 1.6,
                  ),
                ),
              ),

              const Spacer(),

              // Dots indicador
              FadeTransition(
                opacity: _fadeBottom,
                child: Row(
                  children: List.generate(4, (i) {
                    return Container(
                      margin: const EdgeInsets.only(right: 6),
                      width: i == 1 ? 20 : 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: i == 1
                            ? PausaColors.white
                            : PausaColors.textMuted,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    );
                  }),
                ),
              ),

              const SizedBox(height: 24),

              // CTA
              FadeTransition(
                opacity: _fadeBottom,
                child: GestureDetector(
                  onTap: () => context.goNamed('formulario'),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    decoration: BoxDecoration(
                      color: PausaColors.white,
                      borderRadius: BorderRadius.circular(50),
                    ),
                    child: Text(
                      'Continuar',
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