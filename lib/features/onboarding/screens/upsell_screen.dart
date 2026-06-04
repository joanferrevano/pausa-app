import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme.dart';

class UpsellScreen extends StatefulWidget {
  const UpsellScreen({super.key});

  @override
  State<UpsellScreen> createState() => _UpsellScreenState();
}

class _UpsellScreenState extends State<UpsellScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeTop;
  late Animation<double> _fadeFeatures;
  late Animation<double> _fadeBottom;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );

    _fadeTop = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.4, curve: Curves.easeOut),
    );
    _fadeFeatures = CurvedAnimation(
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
              const SizedBox(height: 56),

              // Header
              FadeTransition(
                opacity: _fadeTop,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'pausa puede ayudarte\na recuperar',
                      style: GoogleFonts.dmSerifDisplay(
                        fontSize: 30,
                        height: 1.2,
                        color: PausaColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    RichText(
                      text: TextSpan(
                        style: GoogleFonts.dmSerifDisplay(
                          fontSize: 38,
                          height: 1.1,
                        ),
                        children: const [
                          TextSpan(
                            text: '+5 años ',
                            style: TextStyle(
                              color: PausaColors.white,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                          TextSpan(
                            text: 'de tu vida.',
                            style: TextStyle(color: PausaColors.textMuted),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 48),

              // Features
              FadeTransition(
                opacity: _fadeFeatures,
                child: Column(
                  children: const [
                    _FeatureRow(
                      icon: Icons.hourglass_bottom_rounded,
                      title: 'Pausas',
                      description: 'Pausa antes de entrar a apps que te distraen.',
                    ),
                    SizedBox(height: 20),
                    _FeatureRow(
                      icon: Icons.nights_stay_rounded,
                      title: 'Rutinas',
                      description: 'Bloquea el móvil por las noches automáticamente.',
                    ),
                    SizedBox(height: 20),
                    _FeatureRow(
                      icon: Icons.lock_rounded,
                      title: 'Bloqueos',
                      description: 'Jaulas digitales para cuando necesitas enfocarte.',
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // CTA principal
              FadeTransition(
                opacity: _fadeBottom,
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: () => context.goNamed('registro'),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        decoration: BoxDecoration(
                          color: PausaColors.white,
                          borderRadius: BorderRadius.circular(50),
                        ),
                        child: Text(
                          'Quiero recuperar 5 años',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.dmSans(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: PausaColors.black,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    GestureDetector(
                      onTap: () => context.goNamed('registro'),
                      child: Text(
                        'Continuar sin cuenta',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.dmSans(
                          fontSize: 13,
                          color: PausaColors.textMuted,
                        ),
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
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: PausaColors.border, width: 0.5),
          ),
          child: Icon(icon, color: PausaColors.textSecondary, size: 20),
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
              const SizedBox(height: 3),
              Text(
                description,
                style: GoogleFonts.dmSans(
                  fontSize: 13,
                  color: PausaColors.textMuted,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}