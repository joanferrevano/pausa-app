import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../app/theme.dart';

class AppDef {
  const AppDef(this.name, this.package, this.color);
  final String name;
  final String package;
  final Color color;
}

const kAppDefs = [
  AppDef('Instagram', 'com.instagram.android', Color(0xFFE1306C)),
  AppDef('TikTok', 'com.zhiliaoapp.musically', Color(0xFF010101)),
  AppDef('YouTube', 'com.google.android.youtube', Color(0xFFFF0000)),
  AppDef('Twitter', 'com.twitter.android', Color(0xFF1DA1F2)),
  AppDef('WhatsApp', 'com.whatsapp', Color(0xFF25D366)),
  AppDef('Facebook', 'com.facebook.katana', Color(0xFF1877F2)),
  AppDef('Snapchat', 'com.snapchat.android', Color(0xFFFFFC00)),
  AppDef('Twitch', 'tv.twitch.android.app', Color(0xFF9146FF)),
];

class AppSelectorList extends StatelessWidget {
  const AppSelectorList({
    super.key,
    required this.selectedPackage,
    required this.onSelected,
  });

  final String? selectedPackage;
  final ValueChanged<AppDef> onSelected;

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
      itemBuilder: (_, i) => _AppCell(
        app: kAppDefs[i],
        isSelected: selectedPackage == kAppDefs[i].package,
        onTap: () => onSelected(kAppDefs[i]),
      ),
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
    final initial = widget.app.name[0].toUpperCase();
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
                  initial,
                  style: GoogleFonts.dmSans(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: snapchat ? PausaColors.black : PausaColors.white,
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
                fontWeight: FontWeight.w400,
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

