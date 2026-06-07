import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../app/theme.dart';
import '../../../core/services/accessibility_service.dart';
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
            Expanded(
              child: RefreshIndicator(
                color: PausaColors.white,
                backgroundColor: PausaColors.surface,
                onRefresh: () async {
                  ref.invalidate(accessibilityProvider);
                  final currentPausas = ref.read(pausasProvider);
                  final pausasList = currentPausas
                      .map((p) => p.toMap())
                      .toList();
                  await AccessibilityService.syncPausas(pausasList);
                },
                child: pausas.isEmpty
                    ? _emptyWithBanner(context, ref, accessState)
                    : _listWithBanner(context, ref, pausas, accessState),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: _AddFab(onTap: () => _openSheet(context, ref)),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _banner(BuildContext context, WidgetRef ref) {
    return _AccessibilityBanner(
      onTap: () async {
        await ref.read(accessibilityProvider.notifier).openSettings();
        Future.delayed(const Duration(seconds: 1), () {
          ref.read(accessibilityProvider.notifier).refresh();
        });
      },
    );
  }

  Widget _emptyWithBanner(
    BuildContext context,
    WidgetRef ref,
    AccessibilityState accessState,
  ) {
    return CustomScrollView(
      slivers: [
        if (!accessState.isLoading && !accessState.isEnabled)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
              child: _banner(context, ref),
            ),
          ),
        const SliverFillRemaining(child: EmptyPausasState()),
      ],
    );
  }

  Widget _listWithBanner(
    BuildContext context,
    WidgetRef ref,
    List<PausaConfig> pausas,
    AccessibilityState accessState,
  ) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 120),
      itemCount: pausas.length +
          (!accessState.isLoading && !accessState.isEnabled ? 1 : 0),
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, i) {
        if (!accessState.isLoading && !accessState.isEnabled && i == 0) {
          return _banner(context, ref);
        }
        final idx = (!accessState.isLoading && !accessState.isEnabled) ? i - 1 : i;
        return _FadeSlide(
          delay: Duration(milliseconds: idx * 80),
          child: PausaAppCard(
            config: pausas[idx],
            onToggle: (v) =>
                ref.read(pausasProvider.notifier).togglePausa(idx, v),
            onTap: () => _openSheet(context, ref,
                existing: pausas[idx], editIndex: idx),
            onDelete: () =>
                ref.read(pausasProvider.notifier).deletePausa(idx),
          ),
        );
      },
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
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF4A4A8A), width: 0.5),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.accessibility_new_rounded,
            color: Color(0xFF8A8ADA),
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Activa el permiso de accesibilidad para que las pausas funcionen.',
              style: GoogleFonts.dmSans(
                fontSize: 13,
                color: PausaColors.textSecondary,
                height: 1.5,
              ),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: PausaColors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Activar',
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
