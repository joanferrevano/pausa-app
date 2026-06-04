import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme.dart';

class PausaStatCard extends StatelessWidget {
  final String label;
  final String value;
  final bool isNegative;

  const PausaStatCard({
    super.key,
    required this.label,
    required this.value,
    this.isNegative = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: PausaColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isNegative
              ? PausaColors.red.withAlpha(77)
              : PausaColors.border,
          width: 0.5,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.dmSans(
              fontSize: 13,
              color: PausaColors.textMuted,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.dmSerifDisplay(
              fontSize: 20,
              color: isNegative ? PausaColors.red : PausaColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
