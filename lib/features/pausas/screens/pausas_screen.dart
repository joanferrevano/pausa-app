import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../app/theme.dart';
import '../../../shared/providers/pausas_provider.dart';
import '../../../shared/providers/accessibility_provider.dart';
import '../models/pausa_config.dart';
import '../widgets/pausa_app_card.dart';
import '../widgets/add_pausa_sheet.dart';
import '../widgets/empty_pausas_state.dart';

class PausasScreen extends ConsumerWidget {
  const PausasScreen({super.key});

  Future<void> _openSheet(
    BuildContext context,
    WidgetRef ref, {
    PausaConfig? existing,
    int? editIndex,
  }) async {
    final result = await showModalBottomSheet<PausaConfig>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddPausaSheet(existing: existing),
    );
    if (result == null) return;
    final notifier = ref.read(pausasProvider.notifier);
    if (editIndex != null) {
      await notifier.updatePausa(editIndex, result);
    } else {
      await notifier.addPausa(result);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pausas = ref.watch(pausasProvider);
    final accessState = ref.watch(accessibilityProvider);
    return Scaffold(
      backgroundColor: PausaColors.black,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Header(onAdd: () => _openSheet(context, ref)),
            if (!accessState.isLoading && !accessState.isEnabled)
              _AccessibilityBanner(
                onTap: () async {
                  await ref.read(accessibilityProvider.notifier).openSettings();
                  Future.delayed(const Duration(seconds: 1), () {
                    ref.read(accessibilityProvider.notifier).refresh();
                  });
                },
              ),
            Expanded(
              child: pausas.isEmpty
                  ? const EmptyPausasState()
                  : _PausasList(
                      pausas: pausas,
                      onToggle: (i, v) =>
                          ref.read(pausasProvider.notifier).togglePausa(i, v),
                      onEdit: (i) =>
                          _openSheet(context, ref, existing: pausas[i], editIndex: i),
                      onDelete: (i) =>
                          ref.read(pausasProvider.notifier).deletePausa(i),
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: _AddFab(onTap: () => _openSheet(context, ref)),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.onAdd});
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Pausas',
            style: GoogleFonts.dmSerifDisplay(
              fontSize: 28,
              color: PausaColors.white,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Apps con freno activo',
            style: GoogleFonts.dmSans(
              fontSize: 13,
              color: PausaColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _PausasList extends StatelessWidget {
  const _PausasList({
    required this.pausas,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
  });

  final List<PausaConfig> pausas;
  final void Function(int, bool) onToggle;
  final ValueChanged<int> onEdit;
  final ValueChanged<int> onDelete;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 120),
      itemCount: pausas.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, i) => _FadeSlide(
        delay: Duration(milliseconds: i * 80),
        child: PausaAppCard(
          config: pausas[i],
          onToggle: (v) => onToggle(i, v),
          onTap: () => onEdit(i),
          onDelete: () => onDelete(i),
        ),
      ),
    );
  }
}

class _FadeSlide extends StatefulWidget {
  const _FadeSlide({required this.delay, required this.child});
  final Duration delay;
  final Widget child;

  @override
  State<_FadeSlide> createState() => _FadeSlideState();
}

class _FadeSlideState extends State<_FadeSlide>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _opacity;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _opacity = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.04),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    Future.delayed(widget.delay, () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FadeTransition(
        opacity: _opacity,
        child: SlideTransition(position: _slide, child: widget.child),
      );
}

class _AddFab extends StatefulWidget {
  const _AddFab({required this.onTap});
  final VoidCallback onTap;

  @override
  State<_AddFab> createState() => _AddFabState();
}

class _AccessibilityBanner extends StatelessWidget {
  const _AccessibilityBanner({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 4, 24, 8),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF0F0F1E),
          border: Border.all(color: const Color(0xFF3A3A7A), width: 0.5),
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.accessibility_new_rounded,
                  color: Color(0xFF8A8ADA),
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Activa el servicio de accesibilidad',
                    style: GoogleFonts.dmSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: PausaColors.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Sin este permiso las pausas no pueden interceptar apps.',
              style: GoogleFonts.dmSans(
                fontSize: 12,
                color: PausaColors.textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Xiaomi/POCO: activa también Autostart en Ajustes → Apps → PAUSA\n'
              'Samsung: desactiva optimización de batería para PAUSA\n'
              'Otros: permite que PAUSA se ejecute en segundo plano',
              style: GoogleFonts.dmSans(
                fontSize: 11,
                color: PausaColors.textMuted,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: onTap,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: PausaColors.white,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'Activar ahora',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.dmSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: PausaColors.black,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddFabState extends State<_AddFab> {
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
            height: 52,
            padding: const EdgeInsets.symmetric(horizontal: 32),
            decoration: BoxDecoration(
              color: PausaColors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.add, color: PausaColors.black, size: 18),
                const SizedBox(width: 8),
                Text(
                  'Añadir pausa',
                  style: GoogleFonts.dmSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: PausaColors.black,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
