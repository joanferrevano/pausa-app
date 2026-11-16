import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/services/usage_stats_service.dart';
import '../../../core/widgets/accessibility_warning.dart';

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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
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
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              const BannerButton(
                label: 'Activar',
                onTap: UsageStatsService.openSettings,
                filled: true,
              ),
              BannerButton(
                label: 'Revisar permisos',
                onTap: () => context.pushNamed('revisar-permisos'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
