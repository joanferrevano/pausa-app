import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../app/theme.dart';
import '../../../core/widgets/app_icon_widget.dart';
import '../../../core/widgets/app_picker_sheet.dart';
import '../models/pausa_config.dart';
import 'time_picker_row.dart';

const _waitOptions = ['10s', '15s', '30s', '1min', '2min'];
const _maxOptions = ['5min', '10min', '15min', '20min', '30min', 'Sin límite'];

int _waitToSeconds(String v) {
  if (v.endsWith('min')) return int.parse(v.replaceAll('min', '')) * 60;
  return int.parse(v.replaceAll('s', ''));
}

int _maxToMinutes(String v) {
  if (v == 'Sin límite') return 0;
  return int.parse(v.replaceAll('min', ''));
}

String _secondsToWaitLabel(int s) {
  if (s >= 60) return '${s ~/ 60}min';
  return '${s}s';
}

String _minutesToMaxLabel(int m) {
  if (m == 0) return 'Sin límite';
  return '${m}min';
}

class AddPausaSheet extends StatefulWidget {
  const AddPausaSheet({super.key, this.existing});
  final PausaConfig? existing;

  @override
  State<AddPausaSheet> createState() => _AddPausaSheetState();
}

class _AddPausaSheetState extends State<AddPausaSheet> {
  String? _selectedPackage;
  String? _selectedAppName;
  late String _waitSelected;
  late String _maxSelected;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    if (e != null) {
      _selectedPackage = e.packageName;
      _selectedAppName = e.appName;
      _waitSelected = _secondsToWaitLabel(e.waitSeconds);
      _maxSelected = _minutesToMaxLabel(e.maxMinutes);
    } else {
      _waitSelected = '15s';
      _maxSelected = '20min';
    }
  }

  Future<void> _openPicker() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AppPickerSheet(
        multiSelect: false,
        selectedPackages:
            _selectedPackage != null ? [_selectedPackage!] : [],
        onConfirm: (pkgs) {
          if (pkgs.isNotEmpty) {
            setState(() {
              _selectedPackage = pkgs.first;
              _selectedAppName = pkgs.first;
            });
          }
          Navigator.of(context).pop();
        },
      ),
    );
  }

  void _save() {
    if (_selectedPackage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona una app primero')),
      );
      return;
    }
    final config = PausaConfig(
      appName: _selectedAppName ?? _selectedPackage!,
      packageName: _selectedPackage!,
      waitSeconds: _waitToSeconds(_waitSelected),
      maxMinutes: _maxToMinutes(_maxSelected),
    );
    Navigator.of(context).pop(config);
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
      padding: EdgeInsets.fromLTRB(24, 0, 24, 24 + bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
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
            widget.existing != null ? 'Editar pausa' : 'Nueva pausa',
            style: GoogleFonts.dmSerifDisplay(
                fontSize: 22, color: PausaColors.white),
          ),
          const SizedBox(height: 24),
          _AppPickerRow(
            packageName: _selectedPackage,
            appName: _selectedAppName,
            onTap: _openPicker,
          ),
          const SizedBox(height: 28),
          TimePickerRow(
            label: 'Tiempo de espera antes de entrar',
            options: _waitOptions,
            selected: _waitSelected,
            onSelected: (v) => setState(() => _waitSelected = v),
          ),
          const SizedBox(height: 24),
          TimePickerRow(
            label: 'Tiempo máximo dentro de la app',
            options: _maxOptions,
            selected: _maxSelected,
            onSelected: (v) => setState(() => _maxSelected = v),
          ),
          const SizedBox(height: 32),
          _SaveButton(onTap: _save),
        ],
      ),
    );
  }
}

class _AppPickerRow extends StatelessWidget {
  const _AppPickerRow({
    required this.packageName,
    required this.appName,
    required this.onTap,
  });

  final String? packageName;
  final String? appName;
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
            if (packageName != null)
              AppIconWidget(packageName: packageName!, size: 32)
            else
              const Icon(Icons.apps_rounded,
                  color: PausaColors.textMuted, size: 32),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                packageName != null
                    ? (appName ?? packageName!)
                    : 'Seleccionar app',
                style: GoogleFonts.dmSans(
                  fontSize: 14,
                  color: packageName != null
                      ? PausaColors.textPrimary
                      : PausaColors.textMuted,
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
                'Guardar pausa',
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
