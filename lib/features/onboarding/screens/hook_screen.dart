import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme.dart';

class HookScreen extends StatefulWidget {
  const HookScreen({super.key});

  @override
  State<HookScreen> createState() => _HookScreenState();
}

class _HookScreenState extends State<HookScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeTop;
  late Animation<double> _fadeStat;
  late Animation<double> _fadeBottom;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    );

    _fadeTop = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.4, curve: Curves.easeOut),
    );
    _fadeStat = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.3, 0.7, curve: Curves.easeOut),
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

              // Logo wordmark
              FadeTransition(
                opacity: _fadeTop,
                child: Text(
                  'pausa',
                  style: GoogleFonts.dmSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w300,
                    letterSpacing: 0.2,
                    color: PausaColors.textMuted,
                  ),
                ),
              ),

              const SizedBox(height: 48),

              // Headline
              FadeTransition(
                opacity: _fadeTop,
                child: RichText(
                  text: TextSpan(
                    style: GoogleFonts.dmSerifDisplay(
                      fontSize: 36,
                      height: 1.2,
                      color: PausaColors.textPrimary,
                    ),
                    children: const [
                      TextSpan(text: '¿Te has dado cuenta\nde que pierdes\n'),
                      TextSpan(
                        text: 'demasiado tiempo\n',
                        style: TextStyle(
                          fontStyle: FontStyle.italic,
                          color: PausaColors.textSecondary,
                        ),
                      ),
                      TextSpan(text: 'con el móvil?'),
                    ],
                  ),
                ),
              ),

              const Spacer(),

              // Stat central
              FadeTransition(
                opacity: _fadeStat,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '13',
                      style: GoogleFonts.dmSerifDisplay(
                        fontSize: 96,
                        height: 1.0,
                        color: PausaColors.red,
                      ),
                    ),
                    Text(
                      'años de tu vida',
                      style: GoogleFonts.dmSans(
                        fontSize: 22,
                        fontWeight: FontWeight.w300,
                        color: PausaColors.textPrimary,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Es lo que pierde de media\nuna persona con el móvil.',
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

              // CTA
              FadeTransition(
                opacity: _fadeBottom,
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: () => context.goNamed('dopamina'),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        decoration: BoxDecoration(
                          color: PausaColors.white,
                          borderRadius: BorderRadius.circular(50),
                        ),
                        child: Text(
                          'Descubrir mi número',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.dmSans(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: PausaColors.black,
                            letterSpacing: 0.04,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Gratis · Sin registro',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.dmSans(
                        fontSize: 12,
                        color: PausaColors.textMuted,
                        letterSpacing: 0.06,
                      ),
                    ),
                  ],
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