import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../app/theme.dart';
import '../../../core/models/app_usage_info.dart';
import 'app_usage_row.dart';

const _title = 'Apps más usadas hoy';

class AppUsageCard extends StatelessWidget {
  const AppUsageCard({super.key, required this.apps});

  final List<AppUsageInfo> apps;

  @override
  Widget build(BuildContext context) {
    final display = apps.take(3).toList();
    final maxMs = display.isEmpty ? 1 : display.first.totalTimeMs;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: PausaColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: PausaColors.border, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _title,
            style: GoogleFonts.dmSans(
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: PausaColors.textSecondary,
              letterSpacing: 0.1,
            ),
          ),
          const SizedBox(height: 20),
          if (display.isEmpty)
            Text(
              'Sin datos aún',
              style: GoogleFonts.dmSans(
                fontSize: 13,
                color: PausaColors.textMuted,
              ),
            )
          else
            for (var i = 0; i < display.length; i++) ...[
              AppUsageRow(
                packageName: display[i].packageName,
                appName: display[i].appName,
                timeLabel: display[i].formattedTime,
                fraction: display[i].totalTimeMs / maxMs,
                animationDelay: Duration(milliseconds: 200 + i * 80),
              ),
              if (i < display.length - 1) const SizedBox(height: 16),
            ],
        ],
      ),
    );
  }
}
