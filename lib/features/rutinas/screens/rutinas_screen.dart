import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../app/theme.dart';
import '../../../shared/providers/rutinas_provider.dart';
import '../models/rutina.dart';
import '../widgets/rutina_card.dart';
import '../widgets/add_rutina_sheet.dart';
import '../widgets/empty_rutinas_state.dart';

class RutinasScreen extends ConsumerWidget {
  const RutinasScreen({super.key});

  Future<void> _openSheet(
    BuildContext context,
    WidgetRef ref, {
    Rutina? existing,
  }) async {
    final result = await showModalBottomSheet<Rutina>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddRutinaSheet(existing: existing),
    );
    if (result == null) return;
    final notifier = ref.read(rutinasProvider.notifier);
    if (existing != null) {
      await notifier.updateRutina(result);
    } else {
      await notifier.addRutina(result);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rutinas = ref.watch(rutinasProvider);
    return Scaffold(
      backgroundColor: PausaColors.black,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Header(onAdd: () => _openSheet(context, ref)),
            Expanded(
              child: rutinas.isEmpty
                  ? const EmptyRutinasState()
                  : _RutinasList(
                      rutinas: rutinas,
                      onToggle: (id, v) => ref
                          .read(rutinasProvider.notifier)
                          .toggleRutina(id, v),
                      onEdit: (r) => _openSheet(context, ref, existing: r),
                      onDelete: (id) => ref
                          .read(rutinasProvider.notifier)
                          .deleteRutina(id),
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: _CreateFab(onTap: () => _openSheet(context, ref)),
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
            'Rutinas',
            style: GoogleFonts.dmSerifDisplay(
              fontSize: 28,
              color: PausaColors.white,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Bloqueos automáticos por horario',
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

class _RutinasList extends StatelessWidget {
  const _RutinasList({
    required this.rutinas,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
  });

  final List<Rutina> rutinas;
  final void Function(String, bool) onToggle;
  final ValueChanged<Rutina> onEdit;
  final ValueChanged<String> onDelete;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 120),
      itemCount: rutinas.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, i) => _FadeSlide(
        delay: Duration(milliseconds: i * 80),
        child: RutinaCard(
          rutina: rutinas[i],
          onToggle: (v) => onToggle(rutinas[i].id, v),
          onTap: () => onEdit(rutinas[i]),
          onDelete: () => onDelete(rutinas[i].id),
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
                  'Crear rutina',
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
