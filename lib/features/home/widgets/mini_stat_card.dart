import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../app/theme.dart';

class MiniStatCard extends StatefulWidget {
  const MiniStatCard({
    super.key,
    required this.label,
    required this.value,
    required this.unit,
    this.animationDelay = Duration.zero,
  });

  final String label;
  final int value;
  final String unit;
  final Duration animationDelay;

  @override
  State<MiniStatCard> createState() => _MiniStatCardState();
}

class _MiniStatCardState extends State<MiniStatCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<int> _count;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _count = IntTween(begin: 0, end: widget.value).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOut),
    );
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
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: PausaColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: PausaColors.border, width: 0.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.label,
              style: GoogleFonts.dmSans(
                fontSize: 11,
                fontWeight: FontWeight.w400,
                color: PausaColors.textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 10),
            AnimatedBuilder(
              animation: _count,
              builder: (_, __) => RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: '${_count.value}',
                      style: GoogleFonts.dmSerifDisplay(
                        fontSize: 32,
                        color: PausaColors.white,
                        height: 1.0,
                      ),
                    ),
                    TextSpan(
                      text: ' ${widget.unit}',
                      style: GoogleFonts.dmSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        color: PausaColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
