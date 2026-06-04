import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

part 'rutina.g.dart';

@HiveType(typeId: 1)
class Rutina extends HiveObject {
  Rutina({
    required this.id,
    required this.name,
    required this.days,
    required this.startHour,
    required this.startMinute,
    required this.endHour,
    required this.endMinute,
    required this.appNames,
    this.isActive = true,
  });

  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  List<int> days;

  @HiveField(3)
  int startHour;

  @HiveField(4)
  int startMinute;

  @HiveField(5)
  int endHour;

  @HiveField(6)
  int endMinute;

  @HiveField(7)
  List<String> appNames;

  @HiveField(8)
  bool isActive;

  TimeOfDay get startTime => TimeOfDay(hour: startHour, minute: startMinute);
  TimeOfDay get endTime => TimeOfDay(hour: endHour, minute: endMinute);

  Rutina copyWith({
    String? id,
    String? name,
    List<int>? days,
    TimeOfDay? startTime,
    TimeOfDay? endTime,
    List<String>? appNames,
    bool? isActive,
  }) =>
      Rutina(
        id: id ?? this.id,
        name: name ?? this.name,
        days: days ?? this.days,
        startHour: startTime?.hour ?? startHour,
        startMinute: startTime?.minute ?? startMinute,
        endHour: endTime?.hour ?? endHour,
        endMinute: endTime?.minute ?? endMinute,
        appNames: appNames ?? this.appNames,
        isActive: isActive ?? this.isActive,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'days': days,
        'startHour': startHour,
        'startMinute': startMinute,
        'endHour': endHour,
        'endMinute': endMinute,
        'appNames': appNames,
        'isActive': isActive,
      };

  factory Rutina.fromMap(Map<String, dynamic> m) => Rutina(
        id: m['id'] as String,
        name: m['name'] as String,
        days: List<int>.from(m['days'] as List),
        startHour: m['startHour'] as int,
        startMinute: m['startMinute'] as int,
        endHour: m['endHour'] as int,
        endMinute: m['endMinute'] as int,
        appNames: List<String>.from(m['appNames'] as List),
        isActive: m['isActive'] as bool? ?? true,
      );
}
