import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../app/theme.dart';
import '../../../core/services/accessibility_service.dart';
import '../../../core/widgets/app_icon_widget.dart';
import '../../../shared/providers/pausas_provider.dart';
import '../models/pausa_config.dart';

const _activeColor = Color(0xFF4CAF50);
const _dlgTitleEliminar = 'Eliminar pausa';
const _dlgCancel = 'Cancelar';
const _dlgConfirm = 'Eliminar';

String _waitLabel(int s) => s >= 60 ? '${s ~/ 60}min' : '${s}s';
String _maxLabel(int m) => m == 0 ? '∞' : '${m}min';

class PausaAppCard extends ConsumerStatefulWidget {
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
  ConsumerState<PausaAppCard> createState() => _PausaAppCardState();
}

class _PausaAppCardState extends ConsumerState<PausaAppCard> {
  double _scale = 1.0;
  double _opacity = 1.0;
  bool _inCooldown = false;

  @override
  void initState() {
    super.initState();
    _checkCooldown();
  }

  Future<void> _checkCooldown() async {
    final result = await AccessibilityService.isInDailyCooldown(
      widget.config.packageName,
    );
    if (mounted) setState(() => _inCooldown = result);
  }

  void _down(_) => setState(() { _scale = 0.98; _opacity = 0.85; });
  void _up(_) => setState(() { _scale = 1.0; _opacity = 1.0; });
  void _cancel() => setState(() { _scale = 1.0; _opacity = 1.0; });

  Future<void> _showSkipCooldownDialog() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF161616),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          '¿Esclavo de la dopamina?',
          style: GoogleFonts.dmSerifDisplay(color: const Color(0xFFF0F0F0)),
        ),
        content: Text(
          'Llevas un rato sin esto y ya te rindes.\n\n¿De verdad quieres ser esclavo del algoritmo o puedes más que él?',
          style: GoogleFonts.dmSans(color: const Color(0xFF888888), height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Puedo más',
              style: GoogleFonts.dmSans(color: const Color(0xFFF0F0F0)),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              'Sí, dame el chute',
              style: GoogleFonts.dmSans(
                color: const Color(0xFFE24B4A),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await AccessibilityService.resetDailyCooldown(widget.config.packageName);
      setState(() => _inCooldown = false);
    }
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: PausaColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          _dlgTitleEliminar,
          style: GoogleFonts.dmSans(
            fontWeight: FontWeight.w600,
            color: PausaColors.textPrimary,
          ),
        ),
        content: Text(
          '¿Seguro que quieres eliminar la pausa de ${widget.config.appName}?',
          style: GoogleFonts.dmSans(color: PausaColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              _dlgCancel,
              style: GoogleFonts.dmSans(color: PausaColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              _dlgConfirm,
              style: GoogleFonts.dmSans(
                color: PausaColors.red,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      ref
          .read(pausasProvider.notifier)
          .deletePausaByPackage(widget.config.packageName);
    }
  }

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
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                widget.config.appName,
                                style: GoogleFonts.dmSans(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                  color: PausaColors.textPrimary,
                                ),
                              ),
                            ),
                            GestureDetector(
                              onTap: _confirmDelete,
                              behavior: HitTestBehavior.opaque,
                              child: const Padding(
                                padding: EdgeInsets.only(left: 8),
                                child: Icon(
                                  Icons.delete_outline_rounded,
                                  size: 18,
                                  color: PausaColors.textMuted,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          children: [
                            _InfoChip(
                              icon: Icons.timer_outlined,
                              label:
                                  'Espera: ${_waitLabel(widget.config.waitSeconds)}',
                            ),
                            _InfoChip(
                              icon: Icons.lock_outline_rounded,
                              label:
                                  'Máx: ${_maxLabel(widget.config.maxMinutes)}',
                            ),
                            if (_inCooldown)
                              _CooldownChip(
                                onTap: _showSkipCooldownDialog,
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

class _CooldownChip extends StatelessWidget {
  const _CooldownChip({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        decoration: BoxDecoration(
          color: const Color(0xFF2A1515),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFE24B4A), width: 0.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.block_rounded, size: 12, color: Color(0xFFE24B4A)),
            const SizedBox(width: 5),
            Text(
              'Bloqueado hoy',
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.dmSans(
                fontSize: 11,
                fontWeight: FontWeight.w400,
                color: const Color(0xFFE24B4A),
              ),
            ),
          ],
        ),
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
