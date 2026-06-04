import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme.dart';
import '../../../app/widgets/fade_slide_in.dart';
import '../../../app/widgets/pausa_primary_button.dart';
import '../../../app/widgets/pressable_feedback.dart';

class UpsellScreen extends StatelessWidget {
  final int aniosRecuperables;

  const UpsellScreen({super.key, this.aniosRecuperables = 5});

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
              const SizedBox(height: 56),

              // Header
              FadeSlideIn(
                delay: const Duration(milliseconds: 0),
                duration: const Duration(milliseconds: 500),
                child: Text(
                  'PAUSA puede ayudarte\na recuperar',
                  style: GoogleFonts.dmSerifDisplay(
                    fontSize: 30,
                    height: 1.2,
                    color: PausaColors.textPrimary,
                  ),
                ),
              ),

              const SizedBox(height: 8),

              FadeSlideIn(
                delay: const Duration(milliseconds: 80),
                duration: const Duration(milliseconds: 500),
                child: RichText(
                  text: TextSpan(
                    style: GoogleFonts.dmSerifDisplay(
                      fontSize: 38,
                      height: 1.1,
                    ),
                    children: [
                      TextSpan(
                        text: '+$aniosRecuperables años ',
                        style: const TextStyle(
                          color: PausaColors.white,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                      const TextSpan(
                        text: 'de tu vida.',
                        style: TextStyle(color: PausaColors.textMuted),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 56),

              // Features — staggered
              const FadeSlideIn(
                delay: Duration(milliseconds: 240),
                duration: Duration(milliseconds: 400),
                child: _FeatureRow(
                  icon: Icons.hourglass_bottom_rounded,
                  title: 'Pausas',
                  description:
                      'Una pausa de 5 segundos antes de abrir apps que te atrapan. Simple y efectivo.',
                ),
              ),

              const SizedBox(height: 24),

              const FadeSlideIn(
                delay: Duration(milliseconds: 340),
                duration: Duration(milliseconds: 400),
                child: _FeatureRow(
                  icon: Icons.nights_stay_rounded,
                  title: 'Rutinas',
                  description:
                      'Bloquea el móvil automáticamente por las noches. Duerme mejor, vive más.',
                ),
              ),

              const SizedBox(height: 24),

              const FadeSlideIn(
                delay: Duration(milliseconds: 440),
                duration: Duration(milliseconds: 400),
                child: _FeatureRow(
                  icon: Icons.lock_rounded,
                  title: 'Bloqueos',
                  description:
                      'Encierra apps que te distraen durante el tiempo que necesitas enfocarte.',
                ),
              ),

              const Spacer(),

              // Primary CTA
              FadeSlideIn(
                delay: const Duration(milliseconds: 560),
                duration: const Duration(milliseconds: 400),
                child: PausaPrimaryButton(
                  label: 'Quiero recuperar $aniosRecuperables años',
                  onTap: () => context.goNamed('registro'),
                ),
              ),

              const SizedBox(height: 12),

              // Secondary skip
              FadeSlideIn(
                delay: const Duration(milliseconds: 640),
                duration: const Duration(milliseconds: 400),
                child: PressableFeedback(
                  onTap: () => context.goNamed('registro'),
                  child: SizedBox(
                    width: double.infinity,
                    child: Text(
                      'Continuar sin cuenta',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.dmSans(
                        fontSize: 13,
                        color: PausaColors.textMuted,
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

class _FeatureRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const _FeatureRow({
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: PausaColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: PausaColors.border, width: 0.5),
          ),
          child: Icon(icon, color: PausaColors.textSecondary, size: 18),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.dmSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: PausaColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: GoogleFonts.dmSans(
                  fontSize: 13,
                  color: PausaColors.textMuted,
                  height: 1.55,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
