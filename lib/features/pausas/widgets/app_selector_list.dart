import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../app/theme.dart';
import '../../../core/widgets/app_icon_widget.dart';

class AppDef {
  const AppDef(this.name, this.package);
  final String name;
  final String package;
}

const kAppDefs = [
  AppDef('Instagram', 'com.instagram.android'),
  AppDef('TikTok', 'com.zhiliaoapp.musically'),
  AppDef('YouTube', 'com.google.android.youtube'),
  AppDef('Twitter', 'com.twitter.android'),
  AppDef('WhatsApp', 'com.whatsapp'),
  AppDef('Facebook', 'com.facebook.katana'),
  AppDef('Snapchat', 'com.snapchat.android'),
  AppDef('Twitch', 'tv.twitch.android.app'),
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
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: widget.isSelected
                      ? PausaColors.white
                      : Colors.transparent,
                  width: 2,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: AppIconWidget(
                  packageName: widget.app.package,
                  size: 52,
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
