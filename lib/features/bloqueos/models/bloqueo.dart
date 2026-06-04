class Bloqueo {
  const Bloqueo({
    required this.id,
    required this.name,
    required this.emoji,
    required this.appNames,
    required this.durationMinutes,
    this.isActive = false,
    this.activatedAt,
  });

  final String id;
  final String name;
  final String emoji;
  final List<String> appNames;
  final int durationMinutes; // 0 = until manually disabled
  final bool isActive;
  final DateTime? activatedAt;

  Bloqueo copyWith({
    String? id,
    String? name,
    String? emoji,
    List<String>? appNames,
    int? durationMinutes,
    bool? isActive,
    DateTime? activatedAt,
    bool clearActivatedAt = false,
  }) =>
      Bloqueo(
        id: id ?? this.id,
        name: name ?? this.name,
        emoji: emoji ?? this.emoji,
        appNames: appNames ?? this.appNames,
        durationMinutes: durationMinutes ?? this.durationMinutes,
        isActive: isActive ?? this.isActive,
        activatedAt:
            clearActivatedAt ? null : (activatedAt ?? this.activatedAt),
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'emoji': emoji,
        'appNames': appNames,
        'durationMinutes': durationMinutes,
        'isActive': isActive,
        'activatedAt': activatedAt?.millisecondsSinceEpoch,
      };

  factory Bloqueo.fromMap(Map<String, dynamic> m) => Bloqueo(
        id: m['id'] as String,
        name: m['name'] as String,
        emoji: m['emoji'] as String,
        appNames: List<String>.from(m['appNames'] as List),
        durationMinutes: m['durationMinutes'] as int,
        isActive: m['isActive'] as bool? ?? false,
        activatedAt: m['activatedAt'] != null
            ? DateTime.fromMillisecondsSinceEpoch(m['activatedAt'] as int)
            : null,
      );

  String get durationLabel {
    if (durationMinutes == 0) return 'Manual';
    if (durationMinutes < 60) return '${durationMinutes}min';
    final h = durationMinutes ~/ 60;
    final m = durationMinutes % 60;
    return m == 0 ? '${h}h' : '${h}h ${m}min';
  }
}
