import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../app/theme.dart';
import '../../shared/providers/installed_apps_provider.dart';
import '../../core/models/installed_app.dart';
import 'app_icon_widget.dart';

class AppPickerSheet extends ConsumerStatefulWidget {
  const AppPickerSheet({
    super.key,
    required this.multiSelect,
    required this.selectedPackages,
    required this.onConfirm,
  });

  final bool multiSelect;
  final List<String> selectedPackages;
  final ValueChanged<List<String>> onConfirm;

  @override
  ConsumerState<AppPickerSheet> createState() => _AppPickerSheetState();
}

class _AppPickerSheetState extends ConsumerState<AppPickerSheet> {
  late List<String> _selected;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _selected = List.of(widget.selectedPackages);
  }

  void _toggle(String pkg) {
    setState(() {
      if (widget.multiSelect) {
        _selected.contains(pkg) ? _selected.remove(pkg) : _selected.add(pkg);
      } else {
        _selected = [pkg];
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final bottom = mq.padding.bottom;
    final appsAsync = ref.watch(installedAppsProvider);

    return Container(
      height: mq.size.height * 0.85,
      decoration: const BoxDecoration(
        color: PausaColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
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
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
            child: TextField(
              autofocus: false,
              onChanged: (v) => setState(() => _query = v.toLowerCase()),
              style: GoogleFonts.dmSans(fontSize: 15, color: PausaColors.white),
              decoration: InputDecoration(
                hintText: 'Buscar app…',
                hintStyle: GoogleFonts.dmSans(
                    fontSize: 15, color: PausaColors.textMuted),
                prefixIcon: const Icon(Icons.search_rounded,
                    color: PausaColors.textMuted, size: 20),
                enabledBorder: const UnderlineInputBorder(
                  borderSide:
                      BorderSide(color: PausaColors.border, width: 0.5),
                ),
                focusedBorder: const UnderlineInputBorder(
                  borderSide: BorderSide(color: PausaColors.white, width: 1),
                ),
                contentPadding: const EdgeInsets.only(bottom: 8),
              ),
            ),
          ),
          Expanded(
            child: appsAsync.when(
              loading: () => const Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    color: PausaColors.textMuted,
                    strokeWidth: 1.5,
                  ),
                ),
              ),
              error: (_, __) => Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Error cargando apps. Toca para reintentar',
                      style:
                          GoogleFonts.dmSans(color: PausaColors.textMuted),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: () => ref.refresh(installedAppsProvider),
                      child: Text(
                        'Reintentar',
                        style: GoogleFonts.dmSans(
                          color: PausaColors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              data: (apps) {
                final filtered = _query.isEmpty
                    ? apps
                    : apps
                        .where((a) =>
                            a.appName.toLowerCase().contains(_query) ||
                            a.packageName.toLowerCase().contains(_query))
                        .toList();
                if (filtered.isEmpty) {
                  return Center(
                    child: Text(
                      'No se encontraron apps',
                      style:
                          GoogleFonts.dmSans(color: PausaColors.textMuted),
                    ),
                  );
                }
                return ListView.builder(
                  itemCount: filtered.length,
                  itemBuilder: (_, i) => _AppRow(
                    app: filtered[i],
                    isSelected: _selected.contains(filtered[i].packageName),
                    onTap: () => _toggle(filtered[i].packageName),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding:
                EdgeInsets.fromLTRB(24, 12, 24, 16 + bottom),
            child: _ConfirmButton(
              onTap: () => widget.onConfirm(_selected),
            ),
          ),
        ],
      ),
    );
  }
}

class _AppRow extends StatelessWidget {
  const _AppRow({
    required this.app,
    required this.isSelected,
    required this.onTap,
  });

  final InstalledApp app;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        child: Row(
          children: [
            AppIconWidget(packageName: app.packageName, size: 40),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                app.appName,
                style: GoogleFonts.dmSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: PausaColors.textPrimary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 150),
              child: isSelected
                  ? const Icon(Icons.check_circle_rounded,
                      key: ValueKey(true),
                      color: PausaColors.white,
                      size: 20)
                  : const Icon(Icons.circle_outlined,
                      key: ValueKey(false),
                      color: PausaColors.textMuted,
                      size: 20),
            ),
          ],
        ),
      ),
    );
  }
}

class _ConfirmButton extends StatelessWidget {
  const _ConfirmButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 52,
        decoration: BoxDecoration(
          color: PausaColors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: Text(
            'Confirmar',
            style: GoogleFonts.dmSans(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: PausaColors.black,
            ),
          ),
        ),
      ),
    );
  }
}
