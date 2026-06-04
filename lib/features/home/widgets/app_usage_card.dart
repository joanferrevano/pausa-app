import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../app/theme.dart';
import 'app_usage_row.dart';

const _title = 'Apps más usadas hoy';

const _apps = [
  ('Instagram', '48m', 0.78),
  ('YouTube', '31m', 0.50),
  ('TikTok', '22m', 0.36),
];

class AppUsageCard extends StatelessWidget {
  const AppUsageCard({super.key});

  @override
  Widget build(BuildContext context) {
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
          for (var i = 0; i < _apps.length; i++) ...[
            AppUsageRow(
              appName: _apps[i].$1,
              timeLabel: _apps[i].$2,
              fraction: _apps[i].$3,
              animationDelay: Duration(milliseconds: 200 + i * 80),
            ),
            if (i < _apps.length - 1) const SizedBox(height: 16),
          ],
        ],
      ),
    );
  }
}
