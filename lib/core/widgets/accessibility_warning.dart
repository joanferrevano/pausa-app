import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../shared/providers/accessibility_provider.dart';
import '../services/accessibility_service.dart';

const _bgColor = Color(0xFF2A1F0A);
const _amberColor = Color(0xFFEFB84A);

/// Aviso único (Inicio y Pausas) de que las pausas no van a saltar, con el
/// texto de cada caso:
/// - accesibilidad desactivada en Ajustes;
/// - activada pero con el servicio caído (hay que desactivarla y reactivarla).
/// En Xiaomi, Redmi y POCO explica además el "Inicio automático", que es lo que
/// hace que el sistema apague o no relance el servicio.
///
/// Mostrarlo solo cuando `AccessibilityState.needsAttention` sea true; si no,
/// no ocupa espacio. Se refresca solo al volver a la app.
class AccessibilityWarning extends ConsumerStatefulWidget {
  const AccessibilityWarning({super.key});

  @override
  ConsumerState<AccessibilityWarning> createState() =>
      _AccessibilityWarningState();
}

class _AccessibilityWarningState extends ConsumerState<AccessibilityWarning>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Al volver de Ajustes el estado puede haber cambiado.
    if (state == AppLifecycleState.resumed) {
      ref.read(accessibilityProvider.notifier).refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    final access = ref.watch(accessibilityProvider);
    if (!access.needsAttention) return const SizedBox.shrink();
    final isXiaomi = ref.watch(isXiaomiProvider).valueOrNull ?? false;

    return AccessibilityWarningCard(
      disabled: access.isDisabled,
      isXiaomi: isXiaomi,
      onOpenAccessibility: () =>
          ref.read(accessibilityProvider.notifier).openSettings(),
      onOpenAutostart: AccessibilityService.openAutostartSettings,
      onOpenAppDetails: AccessibilityService.openAppDetails,
    );
  }
}

/// Parte visual del aviso, sin estado.
class AccessibilityWarningCard extends StatelessWidget {
  const AccessibilityWarningCard({
    super.key,
    required this.disabled,
    required this.isXiaomi,
    required this.onOpenAccessibility,
    required this.onOpenAutostart,
    required this.onOpenAppDetails,
  });

  /// true: desactivada en Ajustes. false: activada pero sin funcionar.
  final bool disabled;
  final bool isXiaomi;
  final VoidCallback onOpenAccessibility;
  final VoidCallback onOpenAutostart;
  final VoidCallback onOpenAppDetails;

  String get _title =>
      disabled ? 'La accesibilidad está desactivada' : 'Pausa está detenida';

  String get _body => disabled
      ? 'Sin ese permiso las pausas no saltan. Activa PAUSA en Accesibilidad.'
      : 'La accesibilidad aparece activada, pero el servicio no está '
          'funcionando y las pausas no saltarán. Para arreglarlo, desactiva '
          'PAUSA en Accesibilidad y vuelve a activarlo.';

  String get _xiaomiTitle =>
      disabled ? 'Si ya la habías activado' : 'Para que no vuelva a pasar';

  String get _xiaomiBody => disabled
      ? 'En Xiaomi, Redmi y POCO el sistema la desactiva al cerrar Pausa si '
          'no tiene «Inicio automático». Activa primero el inicio automático '
          'y, en la ficha de la app, pon «Ahorro de batería» en «Sin '
          'restricciones». Después vuelve a activar PAUSA en Accesibilidad.'
      : 'En Xiaomi, Redmi y POCO el sistema cierra Pausa al limpiar las apps '
          'recientes. Activa «Inicio automático» para Pausa y, en la ficha de '
          'la app, pon «Ahorro de batería» en «Sin restricciones».';

  @override
  Widget build(BuildContext context) {
    final accessibilityButton = BannerButton(
      label: 'Abrir Accesibilidad',
      onTap: onOpenAccessibility,
      // En Xiaomi con la accesibilidad apagada, el primer paso es el inicio
      // automático: si no, el sistema la volverá a apagar.
      filled: !(disabled && isXiaomi),
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _amberColor, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.warning_amber_rounded,
                  color: _amberColor, size: 18),
              const SizedBox(width: 8),
              Expanded(child: _text(_title, bold: true, size: 14)),
            ],
          ),
          const SizedBox(height: 8),
          _text(_body),
          if (isXiaomi) ...[
            const SizedBox(height: 12),
            _text(_xiaomiTitle, bold: true),
            const SizedBox(height: 4),
            _text(_xiaomiBody),
          ],
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (isXiaomi && disabled)
                BannerButton(
                  label: 'Inicio automático',
                  onTap: onOpenAutostart,
                  filled: true,
                ),
              accessibilityButton,
              if (isXiaomi && !disabled)
                BannerButton(
                  label: 'Inicio automático',
                  onTap: onOpenAutostart,
                ),
              if (isXiaomi)
                BannerButton(
                  label: 'Ficha de la app',
                  onTap: onOpenAppDetails,
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _text(String text, {bool bold = false, double size = 12}) {
    return Text(
      text,
      style: GoogleFonts.dmSans(
        fontSize: size,
        fontWeight: bold ? FontWeight.w600 : FontWeight.w400,
        color: _amberColor,
        height: 1.4,
      ),
    );
  }
}

class BannerButton extends StatelessWidget {
  const BannerButton({
    super.key,
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
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: filled ? _amberColor : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: _amberColor, width: 0.5),
        ),
        child: Text(
          label,
          style: GoogleFonts.dmSans(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: filled ? Colors.black : _amberColor,
          ),
        ),
      ),
    );
  }
}
