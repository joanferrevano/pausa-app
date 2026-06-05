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
  Future<Uint8List?>? _future;

  @override
  void initState() {
    super.initState();
    if (UsageStatsService.getCachedIcon(widget.packageName) == null) {
      _future = UsageStatsService.getAppIcon(widget.packageName);
    }
  }

  @override
  void didUpdateWidget(AppIconWidget old) {
    super.didUpdateWidget(old);
    if (old.packageName != widget.packageName &&
        UsageStatsService.getCachedIcon(widget.packageName) == null) {
      setState(() {
        _future = UsageStatsService.getAppIcon(widget.packageName);
      });
    }
  }

  Widget _buildIcon(Uint8List bytes) {
    final sz = widget.size;
    return ClipRRect(
      borderRadius: BorderRadius.circular(sz * 0.22),
      child: Image.memory(
        bytes,
        width: sz,
        height: sz,
        fit: BoxFit.cover,
        gaplessPlayback: true,
      ),
    );
  }

  Widget _buildFallback() {
    final sz = widget.size;
    final name = formatAppName(widget.packageName);
    final initial = appInitial(name);
    return Container(
      width: sz,
      height: sz,
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
  }

  @override
  Widget build(BuildContext context) {
    final sz = widget.size;
    final cached = UsageStatsService.getCachedIcon(widget.packageName);

    if (cached != null) {
      return SizedBox(width: sz, height: sz, child: _buildIcon(cached));
    }

    return SizedBox(
      width: sz,
      height: sz,
      child: FutureBuilder<Uint8List?>(
        future: _future,
        builder: (_, snap) {
          if (snap.hasData && snap.data != null) {
            return _buildIcon(snap.data!);
          }
          return _buildFallback();
        },
      ),
    );
  }
}
