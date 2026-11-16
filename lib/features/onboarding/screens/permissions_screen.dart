import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../app/theme.dart';
import '../../../app/widgets/pausa_primary_button.dart';
import '../../../core/services/accessibility_service.dart';
import '../../../core/services/usage_stats_service.dart';
import '../../../shared/providers/accessibility_provider.dart';
import '../../../shared/providers/usage_stats_provider.dart';

const _okColor = Color(0xFF4CAF50);

/// El usuario marca a mano que ha hecho los ajustes de Xiaomi: Android no
/// deja saber si el inicio automático está concedido.
const xiaomiSetupDoneKey = 'xiaomi_setup_done';

/// Permisos que Pausa necesita, cada uno con su estado y un botón que lleva a
/// su ajuste. El estado se vuelve a consultar al volver de Ajustes.
///
/// Con [fromOnboarding] es el último paso del onboarding (sustituye al
/// registro): al terminar marca el onboarding como hecho y va al Inicio.
/// Sin él se abre desde los avisos del Inicio ("Revisar permisos") y al
/// terminar simplemente vuelve atrás.
class PermissionsScreen extends ConsumerStatefulWidget {
  const PermissionsScreen({super.key, required this.fromOnboarding});

  final bool fromOnboarding;

  @override
  ConsumerState<PermissionsScreen> createState() => _PermissionsScreenState();
}

class _PermissionsScreenState extends ConsumerState<PermissionsScreen>
    with WidgetsBindingObserver {
  bool _loading = true;
  bool _notifications = false;
  bool _usage = false;
  bool _accessibility = false;
  bool _isXiaomi = false;
  bool _xiaomiDone = false;
  int _sdkInt = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refresh();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    _refresh();
    // El sistema puede tardar un momento en aplicar lo que se acaba de tocar.
    Future.delayed(const Duration(seconds: 1), _refresh);
  }

  Future<void> _refresh() async {
    final prefs = await SharedPreferences.getInstance();
    final results = await Future.wait<Object>([
      AccessibilityService.areNotificationsEnabled(),
      UsageStatsService.hasPermission(),
      AccessibilityService.isEnabled(),
      AccessibilityService.isXiaomi(),
      AccessibilityService.sdkInt(),
    ]);
    if (!mounted) return;
    setState(() {
      _notifications = results[0] as bool;
      _usage = results[1] as bool;
      _accessibility = results[2] as bool;
      _isXiaomi = results[3] as bool;
      _sdkInt = results[4] as int;
      _xiaomiDone = prefs.getBool(xiaomiSetupDoneKey) ?? false;
      _loading = false;
    });
  }

  Future<void> _requestNotifications() async {
    await AccessibilityService.requestNotifications();
    await _refresh();
  }

  Future<void> _setXiaomiDone(bool value) async {
    setState(() => _xiaomiDone = value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(xiaomiSetupDoneKey, value);
  }

  bool get _essentialsMissing => !_usage || !_accessibility;
  bool get _xiaomiMissing => _isXiaomi && !_xiaomiDone;

  Future<void> _finish() async {
    if (!widget.fromOnboarding) {
      _leave();
      return;
    }
    if (_essentialsMissing || _xiaomiMissing) {
      final go = await _confirmContinue();
      if (go != true || !mounted) return;
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_done', true);
    _leave();
  }

  void _leave() {
    if (!mounted) return;
    // El Inicio muestra sus avisos según estos providers: que estén al día.
    ref.invalidate(accessibilityProvider);
    ref.read(usageStatsProvider.notifier).load();
    if (widget.fromOnboarding) {
      context.goNamed('home');
    } else {
      context.pop();
    }
  }

  Future<bool?> _confirmContinue() {
    final lines = <String>[
      if (_essentialsMissing)
        'Sin el acceso a uso y la accesibilidad, las pausas no funcionarán: '
            'podrás abrir cualquier app sin espera ni límite.',
      if (_xiaomiMissing)
        'Sin el inicio automático, el sistema puede cerrar Pausa y dejará de '
            'funcionar.',
      'Podrás concederlos más tarde desde el Inicio.',
    ];
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: PausaColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          _essentialsMissing
              ? 'Las pausas no funcionarán'
              : 'Pausa puede dejar de funcionar',
          style: GoogleFonts.dmSans(
            fontWeight: FontWeight.w600,
            color: PausaColors.textPrimary,
          ),
        ),
        content: Text(
          lines.join('\n\n'),
          style: GoogleFonts.dmSans(
            color: PausaColors.textSecondary,
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              'Continuar igualmente',
              style: GoogleFonts.dmSans(color: PausaColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Volver',
              style: GoogleFonts.dmSans(
                color: PausaColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    var n = 0;
    final steps = <Widget>[
      _StepCard(
        number: ++n,
        title: 'Notificaciones',
        description: 'Para avisarte cuando se agota tu tiempo en una app.',
        granted: _notifications,
        actions: [
          _StepButton(
            label: 'Permitir notificaciones',
            onTap: _requestNotifications,
            filled: true,
          ),
        ],
      ),
      _StepCard(
        number: ++n,
        title: 'Acceso a uso',
        description: 'Para saber qué app tienes abierta y cuánto la usas.',
        granted: _usage,
        actions: const [
          _StepButton(
            label: 'Abrir acceso a uso',
            onTap: UsageStatsService.openSettings,
            filled: true,
          ),
        ],
      ),
      if (_isXiaomi)
        _StepCard(
          number: ++n,
          title: 'Inicio automático y batería',
          description: 'En Xiaomi, Redmi y POCO el sistema cierra Pausa y '
              'apaga la accesibilidad si no haces esto antes: activa «Inicio '
              'automático» para Pausa y, en la ficha de la app, pon «Ahorro '
              'de batería» en «Sin restricciones».',
          granted: _xiaomiDone,
          grantedLabel: 'Hecho',
          alwaysShowActions: true,
          actions: [
            _StepButton(
              label: 'Inicio automático',
              onTap: AccessibilityService.openAutostartSettings,
              filled: !_xiaomiDone,
            ),
            const _StepButton(
              label: 'Ficha de la app',
              onTap: AccessibilityService.openAppDetails,
            ),
          ],
          footer: _CheckRow(
            label: 'Ya lo he hecho',
            value: _xiaomiDone,
            onChanged: _setXiaomiDone,
          ),
        ),
      _StepCard(
        number: ++n,
        title: 'Accesibilidad',
        description: 'Para mostrar la pausa cuando abres una app. Pausa no '
            'lee lo que hay en tu pantalla.',
        granted: _accessibility,
        note: _sdkInt >= 33
            ? 'Si Android no te deja activarla y dice «Ajuste restringido»:\n'
                '1. Pulsa «Ficha de la app».\n'
                '2. Toca el menú ⋮ de arriba a la derecha y elige «Permitir '
                'ajustes restringidos».\n'
                '3. Vuelve aquí y abre Accesibilidad otra vez.\n'
                'Esa opción solo aparece después de haber intentado activarla '
                'una vez.'
            : null,
        actions: [
          const _StepButton(
            label: 'Abrir Accesibilidad',
            onTap: AccessibilityService.openSettings,
            filled: true,
          ),
          if (_sdkInt >= 33)
            const _StepButton(
              label: 'Ficha de la app',
              onTap: AccessibilityService.openAppDetails,
            ),
        ],
      ),
    ];

    return Scaffold(
      backgroundColor: PausaColors.black,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!widget.fromOnboarding)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: GestureDetector(
                        onTap: _leave,
                        child: const Icon(
                          Icons.arrow_back_rounded,
                          color: PausaColors.textPrimary,
                          size: 22,
                        ),
                      ),
                    ),
                  Text(
                    widget.fromOnboarding ? 'Últimos pasos' : 'Permisos',
                    style: GoogleFonts.dmSerifDisplay(
                      fontSize: 30,
                      height: 1.2,
                      color: PausaColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Pausa necesita estos permisos para funcionar. Nada de '
                    'esto sale de tu móvil.',
                    style: GoogleFonts.dmSans(
                      fontSize: 14,
                      color: PausaColors.textSecondary,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _loading
                  ? const SizedBox.shrink()
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
                      itemCount: steps.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (_, i) => steps[i],
                    ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
              child: Column(
                children: [
                  if (!_loading &&
                      widget.fromOnboarding &&
                      !_notifications &&
                      !_essentialsMissing &&
                      !_xiaomiMissing)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Text(
                        'Sin notificaciones no verás el aviso de tiempo '
                        'agotado.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.dmSans(
                          fontSize: 12,
                          color: PausaColors.textSecondary,
                        ),
                      ),
                    ),
                  PausaPrimaryButton(
                    label: widget.fromOnboarding ? 'Ir al inicio' : 'Hecho',
                    onTap: _loading ? null : _finish,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StepCard extends StatelessWidget {
  const _StepCard({
    required this.number,
    required this.title,
    required this.description,
    required this.granted,
    required this.actions,
    this.grantedLabel = 'Concedido',
    this.note,
    this.footer,
    this.alwaysShowActions = false,
  });

  final int number;
  final String title;
  final String description;
  final bool granted;
  final String grantedLabel;
  final String? note;
  final List<Widget> actions;
  final Widget? footer;
  final bool alwaysShowActions;

  @override
  Widget build(BuildContext context) {
    final showActions = alwaysShowActions || !granted;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: PausaColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: granted ? _okColor.withValues(alpha: 0.5) : PausaColors.border,
          width: 0.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                granted
                    ? Icons.check_circle_rounded
                    : Icons.radio_button_unchecked_rounded,
                color: granted ? _okColor : PausaColors.textMuted,
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '$number. $title',
                  style: GoogleFonts.dmSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: PausaColors.textPrimary,
                  ),
                ),
              ),
              Text(
                granted ? grantedLabel : 'Pendiente',
                style: GoogleFonts.dmSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: granted ? _okColor : PausaColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: GoogleFonts.dmSans(
              fontSize: 13,
              color: PausaColors.textSecondary,
              height: 1.45,
            ),
          ),
          if (note != null && !granted) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: PausaColors.surfaceAlt,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                note!,
                style: GoogleFonts.dmSans(
                  fontSize: 12,
                  color: PausaColors.textSecondary,
                  height: 1.5,
                ),
              ),
            ),
          ],
          if (showActions) ...[
            const SizedBox(height: 12),
            Wrap(spacing: 8, runSpacing: 8, children: actions),
          ],
          if (footer != null) ...[
            const SizedBox(height: 8),
            footer!,
          ],
        ],
      ),
    );
  }
}

class _StepButton extends StatelessWidget {
  const _StepButton({
    required this.label,
    required this.onTap,
    this.filled = false,
  });

  final String label;
  final VoidCallback onTap;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: filled ? PausaColors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: filled ? PausaColors.white : PausaColors.borderStrong,
            width: 0.5,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.dmSans(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: filled ? PausaColors.black : PausaColors.textPrimary,
          ),
        ),
      ),
    );
  }
}

class _CheckRow extends StatelessWidget {
  const _CheckRow({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => onChanged(!value),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Icon(
              value
                  ? Icons.check_box_rounded
                  : Icons.check_box_outline_blank_rounded,
              color: value ? _okColor : PausaColors.textSecondary,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.dmSans(
                fontSize: 13,
                color: PausaColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
