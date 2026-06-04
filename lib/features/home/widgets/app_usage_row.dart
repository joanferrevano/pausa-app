import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../app/theme.dart';

class AppUsageRow extends StatefulWidget {
  const AppUsageRow({
    super.key,
    required this.appName,
    required this.timeLabel,
    required this.fraction,
    required this.animationDelay,
  });

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

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _bar = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    Future.delayed(widget.animationDelay, () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              widget.appName,
              style: GoogleFonts.dmSans(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: PausaColors.textPrimary,
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
              valueColor: const AlwaysStoppedAnimation<Color>(PausaColors.borderStrong),
            ),
          ),
        ),
      ],
    );
  }
}
