import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../app/theme.dart';
import '../models/bloqueo.dart';

const _green = Color(0xFF4CAF50);
const _greenBg = Color(0xFF1A2E1A);

class ActiveBloqueoBanner extends StatefulWidget {
  const ActiveBloqueoBanner({
    super.key,
    required this.bloqueo,
    required this.onDeactivate,
  });

  final Bloqueo bloqueo;
  final VoidCallback onDeactivate;

  @override
  State<ActiveBloqueoBanner> createState() => _ActiveBloqueoBannerState();
}

class _ActiveBloqueoBannerState extends State<ActiveBloqueoBanner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;
  Timer? _tick;
  Duration _remaining = Duration.zero;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _updateRemaining();
    _tick = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(_updateRemaining);
    });
  }

  void _updateRemaining() {
    final b = widget.bloqueo;
    if (b.durationMinutes == 0 || b.activatedAt == null) {
      _remaining = Duration.zero;
      return;
    }
    final end =
        b.activatedAt!.add(Duration(minutes: b.durationMinutes));
    final diff = end.difference(DateTime.now());
    _remaining = diff.isNegative ? Duration.zero : diff;
  }

  String get _timeLabel {
    if (widget.bloqueo.durationMinutes == 0) return 'Manual';
    final h = _remaining.inHours;
    final m = _remaining.inMinutes.remainder(60);
    final s = _remaining.inSeconds.remainder(60);
    if (h > 0) return '${h}h ${m.toString().padLeft(2, '0')}m';
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _pulse.dispose();
    _tick?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: _greenBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _green, width: 0.5),
      ),
      child: Row(
        children: [
          AnimatedBuilder(
            animation: _pulse,
            builder: (_, __) => Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: _green.withValues(alpha: 0.4 + _pulse.value * 0.6),
                shape: BoxShape.circle,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${widget.bloqueo.emoji} ${widget.bloqueo.name}',
                  style: GoogleFonts.dmSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: PausaColors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'activo',
                  style: GoogleFonts.dmSans(
                    fontSize: 11,
                    color: _green,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _timeLabel,
                style: GoogleFonts.dmSerifDisplay(
                  fontSize: 18,
                  color: PausaColors.white,
                  height: 1.0,
                ),
              ),
              const SizedBox(height: 4),
              GestureDetector(
                onTap: widget.onDeactivate,
                child: Text(
                  'Desactivar',
                  style: GoogleFonts.dmSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: PausaColors.red,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
