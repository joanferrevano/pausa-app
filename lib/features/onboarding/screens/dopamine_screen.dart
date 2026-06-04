import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme.dart';
import '../../../app/widgets/fade_slide_in.dart';
import '../../../app/widgets/pausa_primary_button.dart';

class DopamineScreen extends StatelessWidget {
  const DopamineScreen({super.key});

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

              // App name — PAUSA uppercase centered
              FadeSlideIn(
                delay: const Duration(milliseconds: 0),
                duration: const Duration(milliseconds: 400),
                child: Align(
                  alignment: Alignment.center,
                  child: Text(
                    'PAUSA',
                    style: GoogleFonts.dmSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.32,
                      color: PausaColors.textMuted,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 56),

              // Quote — "cocaína" censored + red (alarming comparison)
              FadeSlideIn(
                delay: const Duration(milliseconds: 160),
                duration: const Duration(milliseconds: 600),
                child: RichText(
                  text: TextSpan(
                    style: GoogleFonts.dmSerifDisplay(
                      fontSize: 30,
                      height: 1.35,
                      color: PausaColors.textPrimary,
                    ),
                    children: const [
                      TextSpan(
                        text:
                            'La dopamina que libera\nscrollear en TikTok es\nsimilar a la de la ',
                      ),
                      TextSpan(
                        text: 'c***ína.',
                        style: TextStyle(
                          fontStyle: FontStyle.italic,
                          color: PausaColors.red,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // Red callout — alarming statement
              FadeSlideIn(
                delay: const Duration(milliseconds: 320),
                duration: const Duration(milliseconds: 500),
                child: Text(
                  'Te estás drogando digitalmente.',
                  style: GoogleFonts.dmSerifDisplay(
                    fontSize: 22,
                    height: 1.3,
                    color: PausaColors.red,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // Alarming stat — daily unlocks
              FadeSlideIn(
                delay: const Duration(milliseconds: 480),
                duration: const Duration(milliseconds: 500),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: PausaColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: PausaColors.red.withAlpha(51),
                      width: 0.5,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '2.617',
                        style: GoogleFonts.dmSerifDisplay(
                          fontSize: 48,
                          height: 1.0,
                          color: PausaColors.red,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'veces al día desbloqueas el móvil.',
                        style: GoogleFonts.dmSans(
                          fontSize: 13,
                          color: PausaColors.textMuted,
                          height: 1.6,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const Spacer(),

              // CTA
              FadeSlideIn(
                delay: const Duration(milliseconds: 640),
                duration: const Duration(milliseconds: 500),
                child: PausaPrimaryButton(
                  label: 'Continuar',
                  onTap: () => context.goNamed('formulario'),
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
