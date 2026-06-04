import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../app/theme.dart';

const _dayLabels = ['L', 'M', 'X', 'J', 'V', 'S', 'D'];

class DaySelectorRow extends StatelessWidget {
  const DaySelectorRow({
    super.key,
    required this.selected,
    required this.onToggle,
  });

  final List<int> selected;
  final ValueChanged<int> onToggle;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(
        7,
        (i) => _DayChip(
          label: _dayLabels[i],
          isSelected: selected.contains(i),
          onTap: () => onToggle(i),
        ),
      ),
    );
  }
}

class _DayChip extends StatefulWidget {
  const _DayChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  State<_DayChip> createState() => _DayChipState();
}

class _DayChipState extends State<_DayChip> {
  double _scale = 1.0;

  void _down(_) => setState(() => _scale = 0.9);
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
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color:
                widget.isSelected ? PausaColors.white : PausaColors.surfaceAlt,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: widget.isSelected
                  ? PausaColors.white
                  : PausaColors.borderStrong,
              width: 0.5,
            ),
          ),
          child: Center(
            child: Text(
              widget.label,
              style: GoogleFonts.dmSans(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: widget.isSelected
                    ? PausaColors.black
                    : PausaColors.textMuted,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
