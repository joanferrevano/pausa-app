class PausaConfig {
  const PausaConfig({
    required this.appName,
    required this.packageName,
    required this.waitSeconds,
    required this.maxMinutes,
    this.isActive = true,
  });

  final String appName;
  final String packageName;
  final int waitSeconds;
  final int maxMinutes; // 0 = sin límite
  final bool isActive;

  PausaConfig copyWith({
    String? appName,
    String? packageName,
    int? waitSeconds,
    int? maxMinutes,
    bool? isActive,
  }) {
    return PausaConfig(
      appName: appName ?? this.appName,
      packageName: packageName ?? this.packageName,
      waitSeconds: waitSeconds ?? this.waitSeconds,
      maxMinutes: maxMinutes ?? this.maxMinutes,
      isActive: isActive ?? this.isActive,
    );
  }

  Map<String, dynamic> toMap() => {
        'appName': appName,
        'packageName': packageName,
        'waitSeconds': waitSeconds,
        'maxMinutes': maxMinutes,
        'isActive': isActive,
      };

  factory PausaConfig.fromMap(Map<String, dynamic> map) => PausaConfig(
        appName: map['appName'] as String,
        packageName: map['packageName'] as String,
        waitSeconds: map['waitSeconds'] as int,
        maxMinutes: map['maxMinutes'] as int,
        isActive: map['isActive'] as bool? ?? true,
      );
}
