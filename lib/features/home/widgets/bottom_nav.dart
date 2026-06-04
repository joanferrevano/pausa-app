import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../app/theme.dart';

const _labels = ['Inicio', 'Pausas', 'Rutinas', 'Bloqueos'];
const _icons = [
  Icons.home_outlined,
  Icons.hourglass_bottom_rounded,
  Icons.nights_stay_rounded,
  Icons.lock_outlined,
];

class BottomNav extends StatelessWidget {
  const BottomNav({
    super.key,
    required this.selectedIndex,
    required this.onTap,
  });

  final int selectedIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: PausaColors.black,
        border: Border(
          top: BorderSide(color: PausaColors.border, width: 0.5),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            children: List.generate(
              4,
              (i) => Expanded(child: _NavItem(
                icon: _icons[i],
                label: _labels[i],
                active: selectedIndex == i,
                onTap: () => onTap(i),
              )),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatefulWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  State<_NavItem> createState() => _NavItemState();
}

class _NavItemState extends State<_NavItem> {
  double _scale = 1.0;
  double _opacity = 1.0;

  void _onTapDown(_) => setState(() { _scale = 0.97; _opacity = 0.8; });
  void _onTapUp(_) => setState(() { _scale = 1.0; _opacity = 1.0; });
  void _onTapCancel() => setState(() { _scale = 1.0; _opacity = 1.0; });

  @override
  Widget build(BuildContext context) {
    final color = widget.active ? PausaColors.white : PausaColors.textMuted;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      onTap: widget.onTap,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 120),
        opacity: _opacity,
        child: AnimatedScale(
          duration: const Duration(milliseconds: 120),
          scale: _scale,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(widget.icon, color: color, size: 22),
              const SizedBox(height: 4),
              Text(
                widget.label,
                style: GoogleFonts.dmSans(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: color,
                  letterSpacing: 0.1,
                ),
              ),
              const SizedBox(height: 4),
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: widget.active ? 4 : 0,
                height: widget.active ? 4 : 0,
                decoration: const BoxDecoration(
                  color: PausaColors.white,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
