import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../app/theme.dart';
import '../services/usage_stats_service.dart';
import '../utils/app_name_formatter.dart';

class AppIconWidget extends StatefulWidget {
  const AppIconWidget({
    super.key,
    required this.packageName,
    this.size = 32,
  });

  final String packageName;
  final double size;

  @override
  State<AppIconWidget> createState() => _AppIconWidgetState();
}

class _AppIconWidgetState extends State<AppIconWidget> {
  Uint8List? _bytes;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    final cached = UsageStatsService.getCachedIcon(widget.packageName);
    if (cached != null) {
      _bytes = cached;
      _loaded = true;
    } else {
      _loadIcon();
    }
  }

  @override
  void didUpdateWidget(AppIconWidget old) {
    super.didUpdateWidget(old);
    if (old.packageName != widget.packageName) {
      final cached = UsageStatsService.getCachedIcon(widget.packageName);
      if (cached != null) {
        setState(() { _bytes = cached; _loaded = true; });
      } else {
        setState(() { _bytes = null; _loaded = false; });
        _loadIcon();
      }
    }
  }

  Future<void> _loadIcon() async {
    final bytes = await UsageStatsService.getAppIcon(widget.packageName);
    if (mounted) {
      setState(() { _bytes = bytes; _loaded = true; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final sz = widget.size;

    if (_loaded && _bytes != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(sz * 0.22),
        child: Image.memory(
          _bytes!,
          width: sz,
          height: sz,
          fit: BoxFit.cover,
          gaplessPlayback: true,
        ),
      );
    }

    if (!_loaded) {
      return Container(
        width: sz,
        height: sz,
        decoration: BoxDecoration(
          color: PausaColors.surfaceAlt,
          borderRadius: BorderRadius.circular(sz * 0.22),
        ),
      );
    }

    return _AppIconFallback(packageName: widget.packageName, size: sz);
  }
}

class _AppIconFallback extends StatelessWidget {
  const _AppIconFallback({required this.packageName, required this.size});

  final String packageName;
  final double size;

  @override
  Widget build(BuildContext context) {
    final name = formatAppName(packageName);
    final initial = appInitial(name);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: PausaColors.surfaceAlt,
        shape: BoxShape.circle,
        border: Border.all(color: PausaColors.border, width: 0.5),
      ),
      child: Center(
        child: Text(
          initial,
          style: GoogleFonts.dmSans(
            fontSize: size * 0.4,
            fontWeight: FontWeight.w700,
            color: PausaColors.textSecondary,
          ),
        ),
      ),
    );
  }
}
