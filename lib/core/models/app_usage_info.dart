class AppUsageInfo {
  const AppUsageInfo({
    required this.packageName,
    required this.appName,
    required this.totalTimeMs,
    required this.isUnproductive,
  });

  final String packageName;
  final String appName;
  final int totalTimeMs;
  final bool isUnproductive;

  double get totalTimeMinutes => totalTimeMs / 60000;

  String get formattedTime {
    final totalSeconds = totalTimeMs ~/ 1000;
    final h = totalSeconds ~/ 3600;
    final m = (totalSeconds % 3600) ~/ 60;
    if (totalSeconds < 60) return '< 1m';
    if (h > 0) return '${h}h ${m.toString().padLeft(2, '0')}m';
    return '${m}m';
  }

  factory AppUsageInfo.fromMap(Map<Object?, Object?> map) => AppUsageInfo(
        packageName: map['packageName'] as String,
        appName: map['appName'] as String,
        totalTimeMs: (map['totalTimeMs'] as num).toInt(),
        isUnproductive: map['isUnproductive'] as bool? ?? false,
      );
}
