import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../app/theme.dart';
import '../../../shared/providers/bloqueos_provider.dart';
import '../models/bloqueo.dart';
import 'add_bloqueo_sheet.dart';

const _green = Color(0xFF4CAF50);
const _dlgTitleEliminar = 'Eliminar jaula';
const _dlgCancel = 'Cancelar';
const _dlgConfirm = 'Eliminar';
const _menuEdit = 'Editar jaula';
const _menuDelete = 'Eliminar jaula';

class BloqueoTemplateCard extends ConsumerStatefulWidget {
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
  ConsumerState<BloqueoTemplateCard> createState() =>
      _BloqueoTemplateCardState();
}

class _BloqueoTemplateCardState extends ConsumerState<BloqueoTemplateCard> {
  double _scale = 1.0;

  void _down(_) => setState(() => _scale = 0.97);
  void _up(_) => setState(() => _scale = 1.0);
  void _cancel() => setState(() => _scale = 1.0);

  String get _subtitle {
    final dur = widget.bloqueo.durationLabel;
    final count = widget.bloqueo.appNames.length;
    return count > 0 ? '$dur · $count apps' : dur;
  }

  Future<void> _showMenu() async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _BloqueoMenu(
        onEdit: () async {
          Navigator.of(ctx).pop();
          await _openEditSheet();
        },
        onDelete: () async {
          Navigator.of(ctx).pop();
          await _confirmDelete();
        },
      ),
    );
  }

  Future<void> _openEditSheet() async {
    final result = await showModalBottomSheet<Bloqueo>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddBloqueoSheet(existing: widget.bloqueo),
    );
    if (result == null) return;
    await ref.read(bloqueosProvider.notifier).updateBloqueo(result);
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
          '¿Seguro que quieres eliminar "${widget.bloqueo.name}"?',
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
      ref.read(bloqueosProvider.notifier).deleteBloqueo(widget.bloqueo.id);
    }
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
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      widget.bloqueo.emoji,
                      style: const TextStyle(fontSize: 32),
                    ),
                  ),
                  GestureDetector(
                    onTap: _showMenu,
                    behavior: HitTestBehavior.opaque,
                    child: const Padding(
                      padding: EdgeInsets.only(left: 4),
                      child: Icon(
                        Icons.more_horiz_rounded,
                        size: 20,
                        color: PausaColors.textMuted,
                      ),
                    ),
                  ),
                ],
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

class _BloqueoMenu extends StatelessWidget {
  const _BloqueoMenu({required this.onEdit, required this.onDelete});
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: PausaColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.fromLTRB(0, 8, 0, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: PausaColors.borderStrong,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          _MenuItem(
            icon: Icons.edit_outlined,
            label: _menuEdit,
            color: PausaColors.textPrimary,
            onTap: onEdit,
          ),
          _MenuItem(
            icon: Icons.delete_outline_rounded,
            label: _menuDelete,
            color: PausaColors.red,
            onTap: onDelete,
          ),
        ],
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  const _MenuItem({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 16),
            Text(
              label,
              style: GoogleFonts.dmSans(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: color,
              ),
            ),
          ],
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
