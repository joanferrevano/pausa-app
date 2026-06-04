import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme.dart';
import '../../../app/widgets/fade_slide_in.dart';
import '../../../app/widgets/pausa_primary_button.dart';

class HookScreen extends StatelessWidget {
  const HookScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PausaColors.black,
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 64),

              // Logo wordmark — PAUSA uppercase centered
              FadeSlideIn(
                delay: const Duration(milliseconds: 0),
                duration: const Duration(milliseconds: 500),
                child: Text(
                  'PAUSA',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.dmSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.32,
                    color: PausaColors.textMuted,
                  ),
                ),
              ),

              const SizedBox(height: 56),

              // Headline — centered, key alarming phrase in red
              FadeSlideIn(
                delay: const Duration(milliseconds: 200),
                duration: const Duration(milliseconds: 600),
                child: RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    style: GoogleFonts.dmSerifDisplay(
                      fontSize: 38,
                      height: 1.2,
                      color: PausaColors.textPrimary,
                    ),
                    children: const [
                      TextSpan(text: '¿Te has dado\ncuenta de que\nperdes '),
                      TextSpan(
                        text: 'demasiado\ntiempo',
                        style: TextStyle(
                          fontStyle: FontStyle.italic,
                          color: PausaColors.red,
                        ),
                      ),
                      TextSpan(text: '\ncon el móvil?'),
                    ],
                  ),
                ),
              ),

              const Spacer(),

              // Alarming stat — centered
              FadeSlideIn(
                delay: const Duration(milliseconds: 480),
                duration: const Duration(milliseconds: 600),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      '13',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.dmSerifDisplay(
                        fontSize: 104,
                        height: 1.0,
                        color: PausaColors.red,
                      ),
                    ),
                    Text(
                      'años de tu vida.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.dmSans(
                        fontSize: 24,
                        fontWeight: FontWeight.w300,
                        color: PausaColors.textPrimary,
                        letterSpacing: -0.4,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Es lo que pierde de media una persona\ncon el móvil a lo largo de su vida.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.dmSans(
                        fontSize: 14,
                        color: PausaColors.textMuted,
                        height: 1.65,
                      ),
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // CTA — no secondary text
              FadeSlideIn(
                delay: const Duration(milliseconds: 760),
                duration: const Duration(milliseconds: 500),
                child: PausaPrimaryButton(
                  label: 'Descubrir mi número',
                  onTap: () => context.goNamed('dopamina'),
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
