import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../app/theme.dart';

const kDurationOptions = [
  '15min',
  '30min',
  '45min',
  '1h',
  '2h',
  '4h',
  'Hasta mañana',
  'Manual',
];

int durationLabelToMinutes(String label) {
  switch (label) {
    case '15min':
      return 15;
    case '30min':
      return 30;
    case '45min':
      return 45;
    case '1h':
      return 60;
    case '2h':
      return 120;
    case '4h':
      return 240;
    case 'Hasta mañana':
      return 480;
    default:
      return 0;
  }
}

class BloqueosDurationPicker extends StatelessWidget {
  const BloqueosDurationPicker({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  final String selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final opt in kDurationOptions) ...[
            _DurationChip(
              label: opt,
              isSelected: opt == selected,
              onTap: () => onSelected(opt),
            ),
            const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }
}

class _DurationChip extends StatefulWidget {
  const _DurationChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  State<_DurationChip> createState() => _DurationChipState();
}

class _DurationChipState extends State<_DurationChip> {
  double _scale = 1.0;

  void _down(_) => setState(() => _scale = 0.95);
  void _up(_) => setState(() => _scale = 1.0);
  void _cancel() => setState(() => _scale = 1.0);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _down,
      onTapUp: _up,
      onTapCancel: _cancel,
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 100),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color:
                widget.isSelected ? PausaColors.white : PausaColors.surfaceAlt,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: widget.isSelected
                  ? PausaColors.white
                  : PausaColors.borderStrong,
              width: 0.5,
            ),
          ),
          child: Text(
            widget.label,
            style: GoogleFonts.dmSans(
              fontSize: 13,
              fontWeight:
                  widget.isSelected ? FontWeight.w600 : FontWeight.w400,
              color: widget.isSelected
                  ? PausaColors.black
                  : PausaColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}
