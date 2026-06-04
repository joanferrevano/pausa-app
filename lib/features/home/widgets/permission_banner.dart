import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/services/usage_stats_service.dart';

const _bgColor = Color(0xFF2A1F0A);
const _amberColor = Color(0xFFEFB84A);

class PermissionBanner extends StatelessWidget {
  const PermissionBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: _bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _amberColor, width: 0.5),
      ),
      child: Row(
        children: [
          const Icon(Icons.bar_chart_rounded, color: _amberColor, size: 18),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Activa el permiso de uso para ver tus estadísticas reales',
              style: GoogleFonts.dmSans(
                fontSize: 12,
                color: _amberColor,
                height: 1.4,
              ),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: UsageStatsService.openSettings,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _amberColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Activar',
                style: GoogleFonts.dmSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
