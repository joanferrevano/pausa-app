// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'rutina.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class RutinaAdapter extends TypeAdapter<Rutina> {
  @override
  final int typeId = 1;

  @override
  Rutina read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Rutina(
      id: fields[0] as String,
      name: fields[1] as String,
      days: (fields[2] as List).cast<int>(),
      startHour: fields[3] as int,
      startMinute: fields[4] as int,
      endHour: fields[5] as int,
      endMinute: fields[6] as int,
      appNames: (fields[7] as List).cast<String>(),
      isActive: fields[8] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, Rutina obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.days)
      ..writeByte(3)
      ..write(obj.startHour)
      ..writeByte(4)
      ..write(obj.startMinute)
      ..writeByte(5)
      ..write(obj.endHour)
      ..writeByte(6)
      ..write(obj.endMinute)
      ..writeByte(7)
      ..write(obj.appNames)
      ..writeByte(8)
      ..write(obj.isActive);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RutinaAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
