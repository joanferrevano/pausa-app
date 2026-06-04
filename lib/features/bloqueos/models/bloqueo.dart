import 'package:hive_flutter/hive_flutter.dart';

part 'bloqueo.g.dart';

@HiveType(typeId: 2)
class Bloqueo extends HiveObject {
  Bloqueo({
    required this.id,
    required this.name,
    required this.emoji,
    required this.appNames,
    required this.durationMinutes,
    this.isActive = false,
    this.activatedAtMs,
  });

  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  String emoji;

  @HiveField(3)
  List<String> appNames;

  @HiveField(4)
  int durationMinutes; // 0 = until manually disabled

  @HiveField(5)
  bool isActive;

  @HiveField(6)
  int? activatedAtMs; // DateTime as millisecondsSinceEpoch

  DateTime? get activatedAt => activatedAtMs != null
      ? DateTime.fromMillisecondsSinceEpoch(activatedAtMs!)
      : null;

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
        activatedAtMs: clearActivatedAt
            ? null
            : (activatedAt?.millisecondsSinceEpoch ?? activatedAtMs),
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'emoji': emoji,
        'appNames': appNames,
        'durationMinutes': durationMinutes,
        'isActive': isActive,
        'activatedAtMs': activatedAtMs,
      };

  factory Bloqueo.fromMap(Map<String, dynamic> m) => Bloqueo(
        id: m['id'] as String,
        name: m['name'] as String,
        emoji: m['emoji'] as String,
        appNames: List<String>.from(m['appNames'] as List),
        durationMinutes: m['durationMinutes'] as int,
        isActive: m['isActive'] as bool? ?? false,
        activatedAtMs: m['activatedAtMs'] as int?,
      );

  String get durationLabel {
    if (durationMinutes == 0) return 'Manual';
    if (durationMinutes < 60) return '${durationMinutes}min';
    final h = durationMinutes ~/ 60;
    final m = durationMinutes % 60;
    return m == 0 ? '${h}h' : '${h}h ${m}min';
  }
}
