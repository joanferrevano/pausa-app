import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../app/theme.dart';
import '../../../core/widgets/app_icon_widget.dart';
import '../models/pausa_config.dart';

const _activeColor = Color(0xFF4CAF50);

String _waitLabel(int s) => s >= 60 ? '${s ~/ 60}min' : '${s}s';
String _maxLabel(int m) => m == 0 ? '∞' : '${m}min';

class PausaAppCard extends StatefulWidget {
  const PausaAppCard({
    super.key,
    required this.config,
    required this.onToggle,
    required this.onTap,
    required this.onDelete,
  });

  final PausaConfig config;
  final ValueChanged<bool> onToggle;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  State<PausaAppCard> createState() => _PausaAppCardState();
}

class _PausaAppCardState extends State<PausaAppCard> {
  double _scale = 1.0;
  double _opacity = 1.0;

  void _down(_) => setState(() { _scale = 0.98; _opacity = 0.85; });
  void _up(_) => setState(() { _scale = 1.0; _opacity = 1.0; });
  void _cancel() => setState(() { _scale = 1.0; _opacity = 1.0; });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey(widget.config.packageName),
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
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              decoration: BoxDecoration(
                color: PausaColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: PausaColors.border, width: 0.5),
              ),
              child: Row(
                children: [
                  AppIconWidget(
                    packageName: widget.config.packageName,
                    size: 40,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.config.appName,
                          style: GoogleFonts.dmSans(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: PausaColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.config.packageName,
                          style: GoogleFonts.dmSans(
                            fontSize: 11,
                            color: PausaColors.textMuted,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            _InfoChip(
                              icon: Icons.timer_outlined,
                              label:
                                  'Espera: ${_waitLabel(widget.config.waitSeconds)}',
                            ),
                            const SizedBox(width: 8),
                            _InfoChip(
                              icon: Icons.lock_outline_rounded,
                              label:
                                  'Máx: ${_maxLabel(widget.config.maxMinutes)}',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  _PausaSwitch(
                    value: widget.config.isActive,
                    onChanged: widget.onToggle,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: PausaColors.surfaceAlt,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: PausaColors.border, width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: PausaColors.textSecondary),
          const SizedBox(width: 5),
          Text(
            label,
            style: GoogleFonts.dmSans(
              fontSize: 11,
              fontWeight: FontWeight.w400,
              color: PausaColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _PausaSwitch extends StatelessWidget {
  const _PausaSwitch({required this.value, required this.onChanged});

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
