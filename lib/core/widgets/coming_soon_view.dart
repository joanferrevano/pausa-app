import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../app/theme.dart';

/// Pantalla sencilla para las secciones que aún no bloquean nada de verdad
/// (Rutinas y Bloqueos): icono, título, etiqueta "Próximamente" y una frase.
class ComingSoonView extends StatelessWidget {
  const ComingSoonView({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: PausaColors.surface,
                shape: BoxShape.circle,
                border: Border.all(color: PausaColors.border),
              ),
              child: Icon(icon, color: PausaColors.textSecondary, size: 30),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              textAlign: TextAlign.center,
              style: GoogleFonts.dmSerifDisplay(
                fontSize: 28,
                color: PausaColors.white,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: PausaColors.surfaceAlt,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: PausaColors.borderStrong),
              ),
              child: Text(
                'Próximamente',
                style: GoogleFonts.dmSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: PausaColors.textPrimary,
                  letterSpacing: 0.3,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              description,
              textAlign: TextAlign.center,
              style: GoogleFonts.dmSans(
                fontSize: 14,
                color: PausaColors.textSecondary,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
