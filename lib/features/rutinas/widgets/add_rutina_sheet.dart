import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../app/theme.dart';
import '../../../core/widgets/app_icon_widget.dart';
import '../../../core/widgets/app_picker_sheet.dart';
import '../models/rutina.dart';
import 'day_selector_row.dart';
import 'time_range_row.dart';

class AddRutinaSheet extends StatefulWidget {
  const AddRutinaSheet({super.key, this.existing});
  final Rutina? existing;

  @override
  State<AddRutinaSheet> createState() => _AddRutinaSheetState();
}

class _AddRutinaSheetState extends State<AddRutinaSheet> {
  late final TextEditingController _nameCtrl;
  late List<int> _days;
  late TimeOfDay _start;
  late TimeOfDay _end;
  late List<String> _apps; // package names

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _nameCtrl = TextEditingController(text: e?.name ?? '');
    _days = List.of(e?.days ?? [0, 1, 2, 3, 4]);
    _start = e?.startTime ?? const TimeOfDay(hour: 22, minute: 0);
    _end = e?.endTime ?? const TimeOfDay(hour: 7, minute: 0);
    _apps = List.of(e?.appNames ?? []);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  void _toggleDay(int d) => setState(() {
        _days.contains(d) ? _days.remove(d) : _days.add(d);
      });

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
        const SnackBar(content: Text('Ponle un nombre a la rutina')),
      );
      return;
    }
    if (_days.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona al menos un día')),
      );
      return;
    }
    final rutina = Rutina(
      id: widget.existing?.id ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      name: _nameCtrl.text.trim(),
      days: List.of(_days)..sort(),
      startHour: _start.hour,
      startMinute: _start.minute,
      endHour: _end.hour,
      endMinute: _end.minute,
      appNames: _apps,
    );
    Navigator.of(context).pop(rutina);
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
              widget.existing != null ? 'Editar rutina' : 'Nueva rutina',
              style: GoogleFonts.dmSerifDisplay(
                  fontSize: 22, color: PausaColors.white),
            ),
            const SizedBox(height: 24),
            _NameField(controller: _nameCtrl),
            const SizedBox(height: 28),
            const _SectionLabel(label: 'Días activos'),
            const SizedBox(height: 12),
            DaySelectorRow(selected: _days, onToggle: _toggleDay),
            const SizedBox(height: 28),
            const _SectionLabel(label: 'Horario'),
            const SizedBox(height: 12),
            TimeRangeRow(
              start: _start,
              end: _end,
              onStartChanged: (t) => setState(() => _start = t),
              onEndChanged: (t) => setState(() => _end = t),
            ),
            const SizedBox(height: 28),
            const _SectionLabel(label: 'Apps bloqueadas'),
            const SizedBox(height: 12),
            _MultiAppPickerRow(packages: _apps, onTap: _openPicker),
            const SizedBox(height: 32),
            _SaveButton(onTap: _save),
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
        hintText: 'Nombre de la rutina',
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

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: GoogleFonts.dmSans(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: PausaColors.textSecondary,
        letterSpacing: 0.1,
      ),
    );
  }
}

class _SaveButton extends StatefulWidget {
  const _SaveButton({required this.onTap});
  final VoidCallback onTap;

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
                'Guardar rutina',
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
