import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

const _bgColor = Color(0xFF2A1F0A);
const _amberColor = Color(0xFFEFB84A);

/// Aviso del home cuando la accesibilidad figura como activada en Ajustes pero
/// el servicio no está funcionando: las pausas no saltan hasta reactivarlo.
class ServiceStoppedBanner extends StatelessWidget {
  const ServiceStoppedBanner({
    super.key,
    required this.onOpenAccessibility,
    this.showXiaomiGuide = false,
    this.onOpenAutostart,
    this.onOpenAppDetails,
  });

  final VoidCallback onOpenAccessibility;

  /// En Xiaomi, Redmi y POCO se añade cómo evitar que vuelva a pasar.
  final bool showXiaomiGuide;
  final VoidCallback? onOpenAutostart;
  final VoidCallback? onOpenAppDetails;

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
          if (showXiaomiGuide) ...[
            const SizedBox(height: 16),
            Text(
              'Para que no vuelva a pasar',
              style: GoogleFonts.dmSans(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: _amberColor,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'En Xiaomi, Redmi y POCO el sistema cierra Pausa al limpiar las '
              'apps recientes. Activa «Inicio automático» para Pausa y, en la '
              'ficha de la app, pon «Ahorro de batería» en «Sin restricciones».',
              style: GoogleFonts.dmSans(
                fontSize: 12,
                color: _amberColor,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                BannerButton(
                  label: 'Inicio automático',
                  onTap: onOpenAutostart ?? () {},
                ),
                BannerButton(
                  label: 'Ficha de la app',
                  onTap: onOpenAppDetails ?? () {},
                ),
              ],
            ),
          ],
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
