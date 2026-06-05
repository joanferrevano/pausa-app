import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../app/theme.dart';
import '../../../core/services/usage_stats_service.dart';
import '../../../core/utils/app_name_formatter.dart';

class AppUsageRow extends StatefulWidget {
  const AppUsageRow({
    super.key,
    required this.packageName,
    required this.appName,
    required this.timeLabel,
    required this.fraction,
    required this.animationDelay,
  });

  final String packageName;
  final String appName;
  final String timeLabel;
  final double fraction;
  final Duration animationDelay;

  @override
  State<AppUsageRow> createState() => _AppUsageRowState();
}

class _AppUsageRowState extends State<AppUsageRow>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _bar;
  late final Future<Uint8List?> _iconFuture;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _bar = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _iconFuture = UsageStatsService.getAppIcon(widget.packageName);
    Future.delayed(widget.animationDelay, () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Widget _buildFallback(String initial) => Container(
        decoration: BoxDecoration(
          color: PausaColors.surfaceAlt,
          shape: BoxShape.circle,
          border: Border.all(color: PausaColors.border, width: 0.5),
        ),
        child: Center(
          child: Text(
            initial,
            style: GoogleFonts.dmSans(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: PausaColors.textSecondary,
            ),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final formatted = formatAppName(widget.appName);
    final initial = appInitial(formatted);
    final cached = UsageStatsService.getCachedIcon(widget.packageName);

    return Column(
      children: [
        Row(
          children: [
            SizedBox(
              width: 32,
              height: 32,
              child: FutureBuilder<Uint8List?>(
                future: _iconFuture,
                initialData: cached,
                builder: (_, snap) {
                  final bytes = snap.data;
                  if (bytes != null) {
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.memory(
                        bytes,
                        width: 32,
                        height: 32,
                        fit: BoxFit.cover,
                      ),
                    );
                  }
                  return _buildFallback(initial);
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                formatted,
                style: GoogleFonts.dmSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: PausaColors.textPrimary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(
              widget.timeLabel,
              style: GoogleFonts.dmSans(
                fontSize: 13,
                fontWeight: FontWeight.w400,
                color: PausaColors.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        AnimatedBuilder(
          animation: _bar,
          builder: (_, __) => ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: _bar.value * widget.fraction,
              minHeight: 2,
              backgroundColor: PausaColors.surfaceAlt,
              valueColor: const AlwaysStoppedAnimation<Color>(
                  PausaColors.borderStrong),
            ),
          ),
        ),
      ],
    );
  }
}
