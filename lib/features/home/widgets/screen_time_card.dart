import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../app/theme.dart';
import 'donut_chart.dart';

const _productiveColor = Color(0xFF4CAF50);

const _labelHoy = 'Tiempo de pantalla hoy';
const _labelAyer = 'Ayer: 2h 17m';
const _labelTotal = '2h 34m';
const _labelProductivo = '28m';
const _labelImproductivo = '2h 6m';

class ScreenTimeCard extends StatelessWidget {
  const ScreenTimeCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
      decoration: BoxDecoration(
        color: PausaColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: PausaColors.border, width: 0.5),
      ),
      child: const Column(
        children: [
          _CardHeader(),
          SizedBox(height: 24),
          DonutChart(productive: 0.18, unproductive: 0.72),
          SizedBox(height: 24),
          _StatsRow(),
          SizedBox(height: 16),
          _TotalsRow(),
        ],
      ),
    );
  }
}

class _CardHeader extends StatelessWidget {
  const _CardHeader();

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
        Container(
          width: 24,
          height: 1,
          color: PausaColors.border,
        ),
      ],
    );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(
          child: _StatCell(
            label: 'Productivo',
            value: _labelProductivo,
            valueColor: _productiveColor,
          ),
        ),
        Container(
          width: 0.5,
          height: 36,
          color: PausaColors.border,
        ),
        const Expanded(
          child: _StatCell(
            label: 'Improductivo',
            value: _labelImproductivo,
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
              fontWeight: FontWeight.w400,
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
  const _TotalsRow();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: PausaColors.surfaceAlt,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Text(
                'Total hoy  ',
                style: GoogleFonts.dmSans(
                  fontSize: 12,
                  color: PausaColors.textSecondary,
                ),
              ),
              Text(
                _labelTotal,
                style: GoogleFonts.dmSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: PausaColors.white,
                ),
              ),
            ],
          ),
          Text(
            _labelAyer,
            style: GoogleFonts.dmSans(
              fontSize: 12,
              color: PausaColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
