import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../app/theme.dart';

class MotivationBanner extends StatelessWidget {
  const MotivationBanner({
    super.key,
    required this.streak,
    required this.weeklyRecovered,
  });

  final int streak;
  final String weeklyRecovered;

  @override
  Widget build(BuildContext context) {
    final hasStreak = streak > 0;
    final streakLabel =
        '$streak ${streak == 1 ? "día" : "días"} seguidos sin superar tu meta.';

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
              Icon(
                Icons.local_fire_department_rounded,
                color: hasStreak ? PausaColors.white : PausaColors.textMuted,
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
            hasStreak ? streakLabel : 'Empieza hoy tu racha.',
            style: GoogleFonts.dmSerifDisplay(
              fontSize: 20,
              color: PausaColors.white,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            hasStreak
                ? 'Esta semana has recuperado $weeklyRecovered de tu vida.'
                : 'Cada día que cumples tu meta cuenta.',
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
