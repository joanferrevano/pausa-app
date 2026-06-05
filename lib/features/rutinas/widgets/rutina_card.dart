import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../app/theme.dart';
import '../../../core/widgets/app_icon_widget.dart';
import '../models/rutina.dart';
import '../../pausas/widgets/app_selector_list.dart';

const _activeColor = Color(0xFF4CAF50);
const _dayLabels = ['L', 'M', 'X', 'J', 'V', 'S', 'D'];

String _fmt(TimeOfDay t) =>
    '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

class RutinaCard extends StatefulWidget {
  const RutinaCard({
    super.key,
    required this.rutina,
    required this.onToggle,
    required this.onTap,
    required this.onDelete,
  });

  final Rutina rutina;
  final ValueChanged<bool> onToggle;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  State<RutinaCard> createState() => _RutinaCardState();
}

class _RutinaCardState extends State<RutinaCard> {
  double _scale = 1.0;
  double _opacity = 1.0;

  void _down(_) => setState(() { _scale = 0.98; _opacity = 0.85; });
  void _up(_) => setState(() { _scale = 1.0; _opacity = 1.0; });
  void _cancel() => setState(() { _scale = 1.0; _opacity = 1.0; });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey(widget.rutina.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => widget.onDelete(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        decoration: BoxDecoration(
          color: PausaColors.redMuted,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(
          Icons.delete_outline_rounded,
          color: PausaColors.red,
          size: 22,
        ),
      ),
      child: GestureDetector(
        onTapDown: _down,
        onTapUp: _up,
        onTapCancel: _cancel,
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _scale,
          duration: const Duration(milliseconds: 120),
          child: AnimatedOpacity(
            opacity: _opacity,
            duration: const Duration(milliseconds: 120),
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        widget.rutina.name,
                        style: GoogleFonts.dmSerifDisplay(
                          fontSize: 18,
                          color: PausaColors.white,
                        ),
                      ),
                      _RutinaSwitch(
                        value: widget.rutina.isActive,
                        onChanged: widget.onToggle,
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      _TimeIcon(hour: widget.rutina.startTime.hour),
                      const SizedBox(width: 6),
                      Text(
                        '${_fmt(widget.rutina.startTime)} → ${_fmt(widget.rutina.endTime)}',
                        style: GoogleFonts.dmSans(
                          fontSize: 13,
                          color: PausaColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _DaysRow(days: widget.rutina.days),
                  if (widget.rutina.appNames.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    _AppBubbles(appNames: widget.rutina.appNames),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DaysRow extends StatelessWidget {
  const _DaysRow({required this.days});
  final List<int> days;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(7, (i) {
        final active = days.contains(i);
        return Padding(
          padding: const EdgeInsets.only(right: 6),
          child: Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              color: active ? PausaColors.white : PausaColors.surfaceAlt,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                _dayLabels[i],
                style: GoogleFonts.dmSans(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color:
                      active ? PausaColors.black : PausaColors.textMuted,
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}

class _AppBubbles extends StatelessWidget {
  const _AppBubbles({required this.appNames});
  final List<String> appNames;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: appNames.take(5).map((name) {
        final pkg =
            kAppDefs.where((a) => a.name == name).firstOrNull?.package ?? name;
        return Padding(
          padding: const EdgeInsets.only(right: 6),
          child: AppIconWidget(packageName: pkg, size: 28),
        );
      }).toList(),
    );
  }
}

class _TimeIcon extends StatelessWidget {
  const _TimeIcon({required this.hour});
  final int hour;

  @override
  Widget build(BuildContext context) {
    final isNight = hour >= 20 || hour < 7;
    return Icon(
      isNight ? Icons.nights_stay_rounded : Icons.wb_sunny_rounded,
      size: 14,
      color: isNight ? PausaColors.textMuted : const Color(0xFFEFB84A),
    );
  }
}

class _RutinaSwitch extends StatelessWidget {
  const _RutinaSwitch({required this.value, required this.onChanged});
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 44,
        height: 26,
        decoration: BoxDecoration(
          color: value ? _activeColor : PausaColors.border,
          borderRadius: BorderRadius.circular(13),
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            margin: const EdgeInsets.all(3),
            width: 20,
            height: 20,
            decoration: const BoxDecoration(
              color: PausaColors.white,
              shape: BoxShape.circle,
            ),
          ),
        ),
      ),
    );
  }
}
