import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../app/theme.dart';

const _productiveColor = Color(0xFF4CAF50);
const _donutSize = 140.0;
const _strokeWidth = 10.0;
const _gapDeg = 2.0;

class DonutChart extends StatefulWidget {
  const DonutChart({
    super.key,
    required this.productive,
    required this.unproductive,
  });

  final double productive;
  final double unproductive;

  @override
  State<DonutChart> createState() => _DonutChartState();
}

class _DonutChartState extends State<DonutChart>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _progress;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _progress = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    Future.delayed(const Duration(milliseconds: 80), _ctrl.forward);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  int get _pct => (widget.productive * 100).round();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: _donutSize,
      height: _donutSize,
      child: AnimatedBuilder(
        animation: _progress,
        builder: (_, __) => CustomPaint(
          painter: _DonutPainter(
            productive: widget.productive * _progress.value,
            unproductive: widget.unproductive * _progress.value,
          ),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Productividad',
                  style: GoogleFonts.dmSans(
                    fontSize: 10,
                    fontWeight: FontWeight.w400,
                    color: PausaColors.textMuted,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$_pct%',
                  style: GoogleFonts.dmSerifDisplay(
                    fontSize: 32,
                    color: PausaColors.white,
                    height: 1.0,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DonutPainter extends CustomPainter {
  const _DonutPainter({
    required this.productive,
    required this.unproductive,
  });

  final double productive;
  final double unproductive;

  static const _gap = _gapDeg * math.pi / 180;
  static const _start = -math.pi / 2;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - _strokeWidth) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final trackPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = _strokeWidth
      ..color = PausaColors.surface;

    canvas.drawCircle(center, radius, trackPaint);

    final unprodSweep = unproductive * 2 * math.pi;
    final prodSweep = productive * 2 * math.pi;
    final remaining = math.max(
      0.0,
      2 * math.pi - unprodSweep - prodSweep - 3 * _gap,
    );

    final unprodPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = _strokeWidth
      ..strokeCap = StrokeCap.round
      ..color = PausaColors.red;

    final prodPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = _strokeWidth
      ..strokeCap = StrokeCap.round
      ..color = _productiveColor;

    final neutralPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = _strokeWidth
      ..strokeCap = StrokeCap.round
      ..color = PausaColors.border;

    double cursor = _start;

    if (unprodSweep > 0) {
      canvas.drawArc(rect, cursor, unprodSweep, false, unprodPaint);
      cursor += unprodSweep + _gap;
    }

    if (prodSweep > 0) {
      canvas.drawArc(rect, cursor, prodSweep, false, prodPaint);
      cursor += prodSweep + _gap;
    }

    if (remaining > _gap) {
      canvas.drawArc(rect, cursor, remaining, false, neutralPaint);
    }
  }

  @override
  bool shouldRepaint(_DonutPainter old) =>
      old.productive != productive || old.unproductive != unproductive;
}
