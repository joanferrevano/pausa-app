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
  late Future<Uint8List?> _future;

  @override
  void initState() {
    super.initState();
    _future = UsageStatsService.getAppIcon(widget.packageName);
  }

  @override
  void didUpdateWidget(AppIconWidget old) {
    super.didUpdateWidget(old);
    if (old.packageName != widget.packageName) {
      _future = UsageStatsService.getAppIcon(widget.packageName);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cached = UsageStatsService.getCachedIcon(widget.packageName);
    final displayName = formatAppName(widget.packageName);
    final initial = appInitial(displayName);
    final sz = widget.size;

    return SizedBox(
      width: sz,
      height: sz,
      child: FutureBuilder<Uint8List?>(
        future: _future,
        initialData: cached,
        builder: (_, snap) {
          final bytes = snap.data;
          if (bytes != null) {
            return ClipRRect(
              borderRadius: BorderRadius.circular(sz * 0.25),
              child: Image.memory(
                bytes,
                width: sz,
                height: sz,
                fit: BoxFit.cover,
              ),
            );
          }
          return Container(
            decoration: BoxDecoration(
              color: PausaColors.surfaceAlt,
              shape: BoxShape.circle,
              border: Border.all(color: PausaColors.border, width: 0.5),
            ),
            child: Center(
              child: Text(
                initial,
                style: GoogleFonts.dmSans(
                  fontSize: sz * 0.4,
                  fontWeight: FontWeight.w700,
                  color: PausaColors.textSecondary,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
