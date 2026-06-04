import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../app/theme.dart';
import '../../../core/services/usage_stats_service.dart';
import 'donut_chart.dart';

const _productiveColor = Color(0xFF4CAF50);
const _labelHoy = 'Tiempo de pantalla hoy';

class ScreenTimeCard extends StatelessWidget {
  const ScreenTimeCard({
    super.key,
    required this.totalMs,
    required this.productiveMs,
    required this.unproductiveMs,
  });

  final int totalMs;
  final int productiveMs;
  final int unproductiveMs;

  double get _productiveFraction =>
      totalMs == 0 ? 0 : (productiveMs / totalMs).clamp(0.0, 1.0);

  double get _unproductiveFraction =>
      totalMs == 0 ? 0 : (unproductiveMs / totalMs).clamp(0.0, 1.0);

  @override
  Widget build(BuildContext context) {
    final totalLabel = UsageStatsService.formatDuration(totalMs);
    final productiveLabel = UsageStatsService.formatDuration(productiveMs);
    final unproductiveLabel = UsageStatsService.formatDuration(unproductiveMs);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
      decoration: BoxDecoration(
        color: PausaColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: PausaColors.border, width: 0.5),
      ),
      child: Column(
        children: [
          _CardHeader(),
          const SizedBox(height: 24),
          DonutChart(
            productive: _productiveFraction,
            unproductive: _unproductiveFraction,
          ),
          const SizedBox(height: 24),
          _StatsRow(
            productiveLabel: productiveLabel,
            unproductiveLabel: unproductiveLabel,
          ),
          const SizedBox(height: 16),
          _TotalsRow(totalLabel: totalLabel),
        ],
      ),
    );
  }
}

class _CardHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          _labelHoy,
          style: GoogleFonts.dmSans(
            fontSize: 12,
            fontWeight: FontWeight.w400,
            color: PausaColors.textSecondary,
            letterSpacing: 0.1,
          ),
        ),
        Container(width: 24, height: 1, color: PausaColors.border),
      ],
    );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow({
    required this.productiveLabel,
    required this.unproductiveLabel,
  });

  final String productiveLabel;
  final String unproductiveLabel;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatCell(
            label: 'Productivo',
            value: productiveLabel,
            valueColor: _productiveColor,
          ),
        ),
        Container(width: 0.5, height: 36, color: PausaColors.border),
        Expanded(
          child: _StatCell(
            label: 'Improductivo',
            value: unproductiveLabel,
            valueColor: PausaColors.red,
            align: CrossAxisAlignment.end,
          ),
        ),
      ],
    );
  }
}

class _StatCell extends StatelessWidget {
  const _StatCell({
    required this.label,
    required this.value,
    required this.valueColor,
    this.align = CrossAxisAlignment.start,
  });

  final String label;
  final String value;
  final Color valueColor;
  final CrossAxisAlignment align;

  @override
  Widget build(BuildContext context) {
    final isEnd = align == CrossAxisAlignment.end;
    return Padding(
      padding: EdgeInsets.only(left: isEnd ? 16 : 0, right: isEnd ? 0 : 16),
      child: Column(
        crossAxisAlignment: align,
        children: [
          Text(
            label,
            style: GoogleFonts.dmSans(
              fontSize: 11,
              color: PausaColors.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.dmSans(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: valueColor,
              height: 1.0,
            ),
          ),
        ],
      ),
    );
  }
}

class _TotalsRow extends StatelessWidget {
  const _TotalsRow({required this.totalLabel});
  final String totalLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: PausaColors.surfaceAlt,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Text(
            'Total hoy  ',
            style: GoogleFonts.dmSans(
              fontSize: 12,
              color: PausaColors.textSecondary,
            ),
          ),
          Text(
            totalLabel,
            style: GoogleFonts.dmSans(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: PausaColors.white,
            ),
          ),
        ],
      ),
    );
  }
}
