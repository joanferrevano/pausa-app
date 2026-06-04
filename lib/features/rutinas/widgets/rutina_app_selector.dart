import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../app/theme.dart';
import '../../pausas/widgets/app_selector_list.dart';

class RutinaAppSelector extends StatelessWidget {
  const RutinaAppSelector({
    super.key,
    required this.selectedNames,
    required this.onToggle,
  });

  final List<String> selectedNames;
  final ValueChanged<String> onToggle;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: 16,
        crossAxisSpacing: 8,
        childAspectRatio: 0.75,
      ),
      itemCount: kAppDefs.length,
      itemBuilder: (_, i) {
        final app = kAppDefs[i];
        final selected = selectedNames.contains(app.name);
        return _AppCell(
          app: app,
          isSelected: selected,
          onTap: () => onToggle(app.name),
        );
      },
    );
  }
}

class _AppCell extends StatefulWidget {
  const _AppCell({
    required this.app,
    required this.isSelected,
    required this.onTap,
  });

  final AppDef app;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  State<_AppCell> createState() => _AppCellState();
}

class _AppCellState extends State<_AppCell> {
  double _scale = 1.0;

  void _down(_) => setState(() => _scale = 0.93);
  void _up(_) => setState(() => _scale = 1.0);
  void _cancel() => setState(() => _scale = 1.0);

  @override
  Widget build(BuildContext context) {
    final snapchat = widget.app.package == 'com.snapchat.android';
    return GestureDetector(
      onTapDown: _down,
      onTapUp: _up,
      onTapCancel: _cancel,
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 100),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: widget.app.color,
                shape: BoxShape.circle,
                border: Border.all(
                  color: widget.isSelected
                      ? PausaColors.white
                      : Colors.transparent,
                  width: 2,
                ),
              ),
              child: Center(
                child: Text(
                  widget.app.name[0],
                  style: GoogleFonts.dmSans(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color:
                        snapchat ? PausaColors.black : PausaColors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              widget.app.name,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.dmSans(
                fontSize: 10,
                color: widget.isSelected
                    ? PausaColors.textPrimary
                    : PausaColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
