import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../app/theme.dart';
import '../models/bloqueo.dart';

const _green = Color(0xFF4CAF50);

class BloqueoTemplateCard extends StatefulWidget {
  const BloqueoTemplateCard({
    super.key,
    required this.bloqueo,
    required this.onActivate,
    required this.onDeactivate,
  });

  final Bloqueo bloqueo;
  final VoidCallback onActivate;
  final VoidCallback onDeactivate;

  @override
  State<BloqueoTemplateCard> createState() => _BloqueoTemplateCardState();
}

class _BloqueoTemplateCardState extends State<BloqueoTemplateCard> {
  double _scale = 1.0;

  void _down(_) => setState(() => _scale = 0.97);
  void _up(_) => setState(() => _scale = 1.0);
  void _cancel() => setState(() => _scale = 1.0);

  String get _subtitle {
    final dur = widget.bloqueo.durationLabel;
    final count = widget.bloqueo.appNames.length;
    return count > 0 ? '$dur · $count apps' : dur;
  }

  @override
  Widget build(BuildContext context) {
    final active = widget.bloqueo.isActive;
    return GestureDetector(
      onTapDown: _down,
      onTapUp: _up,
      onTapCancel: _cancel,
      onTap: active ? widget.onDeactivate : widget.onActivate,
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 120),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: PausaColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: active ? _green : PausaColors.border,
              width: 0.5,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.bloqueo.emoji,
                style: const TextStyle(fontSize: 32),
              ),
              const SizedBox(height: 10),
              Text(
                widget.bloqueo.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.dmSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: PausaColors.textPrimary,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _subtitle,
                style: GoogleFonts.dmSans(
                  fontSize: 11,
                  color: PausaColors.textSecondary,
                ),
              ),
              const Spacer(),
              _ActivateButton(
                isActive: active,
                onTap: active ? widget.onDeactivate : widget.onActivate,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActivateButton extends StatelessWidget {
  const _ActivateButton({required this.isActive, required this.onTap});

  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        height: 32,
        decoration: BoxDecoration(
          color: isActive ? _green : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: isActive
              ? null
              : Border.all(color: PausaColors.borderStrong, width: 0.5),
        ),
        child: Center(
          child: Text(
            isActive ? 'Activo' : 'Activar',
            style: GoogleFonts.dmSans(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isActive ? PausaColors.white : PausaColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}
