import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../app/theme.dart';
import '../../../shared/providers/bloqueos_provider.dart';
import '../models/bloqueo.dart';
import '../widgets/bloqueo_template_card.dart';
import '../widgets/active_bloqueo_banner.dart';
import '../widgets/add_bloqueo_sheet.dart';
import '../widgets/empty_bloqueos_state.dart';

class BloqueosScreen extends ConsumerWidget {
  const BloqueosScreen({super.key});

  Future<void> _openSheet(
    BuildContext context,
    WidgetRef ref, {
    Bloqueo? existing,
  }) async {
    final result = await showModalBottomSheet<Bloqueo>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddBloqueoSheet(existing: existing),
    );
    if (result == null) return;
    await ref.read(bloqueosProvider.notifier).addBloqueo(result);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bloqueos = ref.watch(bloqueosProvider);
    final active = bloqueos.where((b) => b.isActive).firstOrNull;
    final notifier = ref.read(bloqueosProvider.notifier);

    return Scaffold(
      backgroundColor: PausaColors.black,
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _Header(onAdd: () => _openSheet(context, ref)),
                    if (active != null) ...[
                      const SizedBox(height: 16),
                      ActiveBloqueoBanner(
                        bloqueo: active,
                        onDeactivate: () =>
                            notifier.deactivateBloqueo(active.id),
                      ),
                    ],
                    const SizedBox(height: 24),
                    Text(
                      'Plantillas',
                      style: GoogleFonts.dmSans(
                        fontSize: 12,
                        color: PausaColors.textSecondary,
                        letterSpacing: 0.1,
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),
            if (bloqueos.isEmpty)
              const SliverFillRemaining(child: EmptyBloqueosState())
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 120),
                sliver: SliverGrid(
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 0.9,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (_, i) => _FadeSlide(
                      delay: Duration(milliseconds: i * 80),
                      child: BloqueoTemplateCard(
                        bloqueo: bloqueos[i],
                        onActivate: () =>
                            notifier.activateBloqueo(bloqueos[i].id),
                        onDeactivate: () =>
                            notifier.deactivateBloqueo(bloqueos[i].id),
                      ),
                    ),
                    childCount: bloqueos.length,
                  ),
                ),
              ),
          ],
        ),
      ),
      floatingActionButton:
          _CreateFab(onTap: () => _openSheet(context, ref)),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.onAdd});
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Bloqueos',
          style: GoogleFonts.dmSerifDisplay(
            fontSize: 28,
            color: PausaColors.white,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Jaulas de enfoque bajo demanda',
          style: GoogleFonts.dmSans(
            fontSize: 13,
            color: PausaColors.textSecondary,
          ),
        ),
      ],
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

class _CreateFab extends StatefulWidget {
  const _CreateFab({required this.onTap});
  final VoidCallback onTap;

  @override
  State<_CreateFab> createState() => _CreateFabState();
}

class _CreateFabState extends State<_CreateFab> {
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
                  'Crear jaula',
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
