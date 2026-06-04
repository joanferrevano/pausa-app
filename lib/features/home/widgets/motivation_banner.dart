import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../app/theme.dart';

const _headline = '7 días seguidos sin superar tu meta.';
const _sub = 'Esta semana has recuperado 4h 12m de tu vida.';

class MotivationBanner extends StatelessWidget {
  const MotivationBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: PausaColors.surfaceAlt,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: PausaColors.border, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.local_fire_department_rounded,
                color: PausaColors.white,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                'Racha activa',
                style: GoogleFonts.dmSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: PausaColors.textSecondary,
                  letterSpacing: 0.4,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _headline,
            style: GoogleFonts.dmSerifDisplay(
              fontSize: 20,
              color: PausaColors.white,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _sub,
            style: GoogleFonts.dmSans(
              fontSize: 13,
              fontWeight: FontWeight.w400,
              color: PausaColors.textSecondary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
