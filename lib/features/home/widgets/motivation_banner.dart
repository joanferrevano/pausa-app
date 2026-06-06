import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../app/theme.dart';

const _labelRachaActiva = 'Racha activa';
const _titleStart = 'Empieza hoy tu racha.';
const _subtitleStart = 'Cada día que cumplas tu meta, lo verás aquí.';
const _subtitleRecovered = 'Esta semana has recuperado';
const _subtitleRecoveredSuffix = 'de tu vida.';

class MotivationBanner extends StatelessWidget {
  const MotivationBanner({
    super.key,
    required this.streak,
    required this.weeklyRecovered,
  });

  final int streak;
  final String weeklyRecovered;

  String get _title {
    if (streak == 0) return _titleStart;
    if (streak == 1) return '1 día seguido. 🔥';
    return '$streak días seguidos sin superar tu meta. 🔥';
  }

  String get _subtitle {
    if (streak == 0) return _subtitleStart;
    return '$_subtitleRecovered $weeklyRecovered $_subtitleRecoveredSuffix';
  }

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
              Icon(
                Icons.local_fire_department_rounded,
                color: streak > 0 ? PausaColors.white : PausaColors.textMuted,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                _labelRachaActiva,
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
            _title,
            style: GoogleFonts.dmSerifDisplay(
              fontSize: 20,
              color: PausaColors.white,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _subtitle,
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
