import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

const _bgColor = Color(0xFF2A1F0A);
const _amberColor = Color(0xFFEFB84A);

/// Aviso del home cuando la accesibilidad figura como activada en Ajustes pero
/// el servicio no está funcionando: las pausas no saltan hasta reactivarlo.
class ServiceStoppedBanner extends StatelessWidget {
  const ServiceStoppedBanner({super.key, required this.onOpenAccessibility});

  final VoidCallback onOpenAccessibility;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _amberColor, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.warning_amber_rounded,
                  color: _amberColor, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Pausa está detenida',
                  style: GoogleFonts.dmSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _amberColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'La accesibilidad aparece activada, pero el servicio no está '
            'funcionando y las pausas no saltarán. Para arreglarlo, desactiva '
            'PAUSA en Accesibilidad y vuelve a activarlo.',
            style: GoogleFonts.dmSans(
              fontSize: 12,
              color: _amberColor,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          BannerButton(
            label: 'Abrir Accesibilidad',
            onTap: onOpenAccessibility,
            filled: true,
          ),
        ],
      ),
    );
  }
}

class BannerButton extends StatelessWidget {
  const BannerButton({
    super.key,
    required this.label,
    required this.onTap,
    this.filled = false,
  });

  final String label;
  final VoidCallback onTap;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: filled ? _amberColor : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: _amberColor, width: 0.5),
        ),
        child: Text(
          label,
          style: GoogleFonts.dmSans(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: filled ? Colors.black : _amberColor,
          ),
        ),
      ),
    );
  }
}
