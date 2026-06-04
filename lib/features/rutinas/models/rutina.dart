import 'package:flutter/material.dart';

class Rutina {
  const Rutina({
    required this.id,
    required this.name,
    required this.days,
    required this.startTime,
    required this.endTime,
    required this.appNames,
    this.isActive = true,
  });

  final String id;
  final String name;
  final List<int> days;
  final TimeOfDay startTime;
  final TimeOfDay endTime;
  final List<String> appNames;
  final bool isActive;

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
        startTime: startTime ?? this.startTime,
        endTime: endTime ?? this.endTime,
        appNames: appNames ?? this.appNames,
        isActive: isActive ?? this.isActive,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'days': days,
        'startHour': startTime.hour,
        'startMinute': startTime.minute,
        'endHour': endTime.hour,
        'endMinute': endTime.minute,
        'appNames': appNames,
        'isActive': isActive,
      };

  factory Rutina.fromMap(Map<String, dynamic> m) => Rutina(
        id: m['id'] as String,
        name: m['name'] as String,
        days: List<int>.from(m['days'] as List),
        startTime: TimeOfDay(
          hour: m['startHour'] as int,
          minute: m['startMinute'] as int,
        ),
        endTime: TimeOfDay(
          hour: m['endHour'] as int,
          minute: m['endMinute'] as int,
        ),
        appNames: List<String>.from(m['appNames'] as List),
        isActive: m['isActive'] as bool? ?? true,
      );
}
