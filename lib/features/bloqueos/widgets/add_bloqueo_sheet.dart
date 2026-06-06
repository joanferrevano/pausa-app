import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../app/theme.dart';
import '../../../core/widgets/app_icon_widget.dart';
import '../../../core/widgets/app_picker_sheet.dart';
import '../models/bloqueo.dart';
import 'bloqueo_duration_picker.dart';

const _emojis = [
  '🎯', '📚', '🏋️', '🌙', '💼', '🧘',
  '🚫', '⚡', '🔕', '💪', '🎮', '✍️',
];

class AddBloqueoSheet extends StatefulWidget {
  const AddBloqueoSheet({super.key, this.existing});
  final Bloqueo? existing;

  @override
  State<AddBloqueoSheet> createState() => _AddBloqueoSheetState();
}

class _AddBloqueoSheetState extends State<AddBloqueoSheet> {
  late final TextEditingController _nameCtrl;
  late String _emoji;
  late List<String> _apps; // package names
  late String _duration;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _nameCtrl = TextEditingController(text: e?.name ?? '');
    _emoji = e?.emoji ?? '🎯';
    _apps = List.of(e?.appNames ?? []);
    _duration = e != null ? _minutesToLabel(e.durationMinutes) : '1h';
  }

  String _minutesToLabel(int m) {
    switch (m) {
      case 15: return '15min';
      case 30: return '30min';
      case 45: return '45min';
      case 60: return '1h';
      case 120: return '2h';
      case 240: return '4h';
      case 480: return 'Hasta mañana';
      default: return 'Manual';
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _openPicker() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AppPickerSheet(
        multiSelect: true,
        selectedPackages: _apps,
        onConfirm: (pkgs) {
          setState(() => _apps = pkgs);
          Navigator.of(context).pop();
        },
      ),
    );
  }

  void _save() {
    if (_nameCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ponle un nombre a la jaula')),
      );
      return;
    }
    final bloqueo = Bloqueo(
      id: widget.existing?.id ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      name: _nameCtrl.text.trim(),
      emoji: _emoji,
      appNames: _apps,
      durationMinutes: durationLabelToMinutes(_duration),
    );
    Navigator.of(context).pop(bloqueo);
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final bottom = mq.viewInsets.bottom + mq.padding.bottom;
    return Container(
      decoration: const BoxDecoration(
        color: PausaColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(24, 0, 24, 24 + bottom),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: PausaColors.borderStrong,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Text(
              widget.existing != null ? 'Editar jaula' : 'Nueva jaula',
              style: GoogleFonts.dmSerifDisplay(
                  fontSize: 22, color: PausaColors.white),
            ),
            const SizedBox(height: 24),
            _NameField(controller: _nameCtrl),
            const SizedBox(height: 28),
            const _SectionLabel(label: 'Icono'),
            const SizedBox(height: 12),
            _EmojiPicker(
              selected: _emoji,
              onSelected: (e) => setState(() => _emoji = e),
            ),
            const SizedBox(height: 28),
            const _SectionLabel(label: 'Apps bloqueadas'),
            const SizedBox(height: 12),
            _MultiAppPickerRow(packages: _apps, onTap: _openPicker),
            const SizedBox(height: 28),
            const _SectionLabel(label: 'Duración'),
            const SizedBox(height: 12),
            BloqueosDurationPicker(
              selected: _duration,
              onSelected: (v) => setState(() => _duration = v),
            ),
            const SizedBox(height: 32),
            _SaveButton(
              onTap: _save,
              label: widget.existing != null ? 'Guardar cambios' : 'Crear jaula',
            ),
          ],
        ),
      ),
    );
  }
}

class _MultiAppPickerRow extends StatelessWidget {
  const _MultiAppPickerRow({required this.packages, required this.onTap});
  final List<String> packages;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: PausaColors.surfaceAlt,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: PausaColors.border, width: 0.5),
        ),
        child: Row(
          children: [
            if (packages.isEmpty)
              const Icon(Icons.apps_rounded,
                  color: PausaColors.textMuted, size: 28)
            else
              ...packages.take(5).map(
                    (pkg) => Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: AppIconWidget(packageName: pkg, size: 28),
                    ),
                  ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                packages.isEmpty
                    ? 'Seleccionar apps'
                    : '${packages.length} app${packages.length == 1 ? '' : 's'}',
                style: GoogleFonts.dmSans(
                  fontSize: 14,
                  color: packages.isEmpty
                      ? PausaColors.textMuted
                      : PausaColors.textSecondary,
                ),
              ),
            ),
            const Icon(Icons.chevron_right_rounded,
                color: PausaColors.textMuted, size: 20),
          ],
        ),
      ),
    );
  }
}

class _NameField extends StatelessWidget {
  const _NameField({required this.controller});
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      style: GoogleFonts.dmSans(fontSize: 16, color: PausaColors.white),
      decoration: InputDecoration(
        hintText: 'Nombre de la jaula',
        hintStyle:
            GoogleFonts.dmSans(fontSize: 16, color: PausaColors.textMuted),
        enabledBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: PausaColors.border, width: 0.5),
        ),
        focusedBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: PausaColors.white, width: 1),
        ),
        contentPadding: const EdgeInsets.only(bottom: 8),
      ),
    );
  }
}

class _EmojiPicker extends StatelessWidget {
  const _EmojiPicker({required this.selected, required this.onSelected});
  final String selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _emojis.map((e) {
          final isSelected = e == selected;
          return GestureDetector(
            onTap: () => onSelected(e),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              margin: const EdgeInsets.only(right: 8),
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color:
                    isSelected ? PausaColors.surfaceAlt : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isSelected
                      ? PausaColors.white
                      : PausaColors.borderStrong,
                  width: isSelected ? 1 : 0.5,
                ),
              ),
              child: Center(
                child: Text(e, style: const TextStyle(fontSize: 22)),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: GoogleFonts.dmSans(
        fontSize: 12,
        color: PausaColors.textSecondary,
        letterSpacing: 0.1,
      ),
    );
  }
}

class _SaveButton extends StatefulWidget {
  const _SaveButton({required this.onTap, required this.label});
  final VoidCallback onTap;
  final String label;

  @override
  State<_SaveButton> createState() => _SaveButtonState();
}

class _SaveButtonState extends State<_SaveButton> {
  double _scale = 1.0;
  double _opacity = 1.0;

  void _down(_) => setState(() { _scale = 0.97; _opacity = 0.85; });
  void _up(_) => setState(() { _scale = 1.0; _opacity = 1.0; });
  void _cancel() => setState(() { _scale = 1.0; _opacity = 1.0; });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
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
            width: double.infinity,
            height: 52,
            decoration: BoxDecoration(
              color: PausaColors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Text(
                widget.label,
                style: GoogleFonts.dmSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: PausaColors.black,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
