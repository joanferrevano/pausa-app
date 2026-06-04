import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme.dart';
import '../../../app/widgets/fade_slide_in.dart';
import '../../../app/widgets/pausa_primary_button.dart';
import '../../../app/widgets/pausa_stat_card.dart';
import '../../../app/widgets/count_up_text.dart';

class ResultScreen extends StatelessWidget {
  final Map<String, dynamic>? extra;
  const ResultScreen({super.key, this.extra});

  @override
  Widget build(BuildContext context) {
    final nombre = extra?['nombre'] as String? ?? '';
    final diasAno = extra?['diasAno'] as int? ?? 0;
    final aniosVida = extra?['aniosVida'] as int? ?? 0;
    final aniosRecuperables = extra?['aniosRecuperables'] as int? ?? 0;

    return Scaffold(
      backgroundColor: PausaColors.black,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 48),

                // Greeting
                FadeSlideIn(
                  delay: const Duration(milliseconds: 0),
                  duration: const Duration(milliseconds: 400),
                  child: Text(
                    nombre.isNotEmpty ? nombre : 'Tu resultado',
                    style: GoogleFonts.dmSans(
                      fontSize: 13,
                      color: PausaColors.textMuted,
                      letterSpacing: 0.08,
                    ),
                  ),
                ),

                const SizedBox(height: 8),

                FadeSlideIn(
                  delay: const Duration(milliseconds: 80),
                  duration: const Duration(milliseconds: 500),
                  child: Text(
                    'Este es el tiempo\nque estás perdiendo.',
                    style: GoogleFonts.dmSerifDisplay(
                      fontSize: 30,
                      height: 1.2,
                      color: PausaColors.textPrimary,
                    ),
                  ),
                ),

                const SizedBox(height: 56),

                // Hero stat — dramatic, full-width, count-up
                FadeSlideIn(
                  delay: const Duration(milliseconds: 240),
                  duration: const Duration(milliseconds: 600),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Alarming number — red justified (years of life lost)
                      CountUpText(
                        target: aniosVida,
                        duration: const Duration(milliseconds: 1400),
                        style: GoogleFonts.dmSerifDisplay(
                          fontSize: 96,
                          height: 1.0,
                          color: PausaColors.red,
                        ),
                      ),
                      Text(
                        'años de tu vida.',
                        style: GoogleFonts.dmSans(
                          fontSize: 22,
                          fontWeight: FontWeight.w300,
                          color: PausaColors.textPrimary,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 8),

                // Thin separator
                FadeSlideIn(
                  delay: const Duration(milliseconds: 320),
                  duration: const Duration(milliseconds: 400),
                  child: Container(
                    height: 0.5,
                    width: double.infinity,
                    color: PausaColors.border,
                  ),
                ),

                const SizedBox(height: 32),

                // Stat cards — staggered entrances
                FadeSlideIn(
                  delay: const Duration(milliseconds: 480),
                  duration: const Duration(milliseconds: 400),
                  child: PausaStatCard(
                    label: 'Este año perderás',
                    value: '$diasAno días',
                    isNegative: true,
                  ),
                ),

                const SizedBox(height: 8),

                FadeSlideIn(
                  delay: const Duration(milliseconds: 560),
                  duration: const Duration(milliseconds: 400),
                  child: PausaStatCard(
                    label: 'A lo largo de tu vida',
                    value: '$aniosVida años',
                    isNegative: true,
                  ),
                ),

                const SizedBox(height: 8),

                FadeSlideIn(
                  delay: const Duration(milliseconds: 640),
                  duration: const Duration(milliseconds: 400),
                  child: PausaStatCard(
                    label: 'Podrías recuperar',
                    value: '+$aniosRecuperables años',
                    isNegative: false,
                  ),
                ),

                const SizedBox(height: 48),

                // CTA
                FadeSlideIn(
                  delay: const Duration(milliseconds: 800),
                  duration: const Duration(milliseconds: 400),
                  child: PausaPrimaryButton(
                    label: 'Quiero recuperar esos años',
                    onTap: () => context.goNamed('upsell', extra: {'aniosRecuperables': aniosRecuperables}),
                  ),
                ),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
