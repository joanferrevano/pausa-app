// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'bloqueo.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class BloqueoAdapter extends TypeAdapter<Bloqueo> {
  @override
  final int typeId = 2;

  @override
  Bloqueo read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Bloqueo(
      id: fields[0] as String,
      name: fields[1] as String,
      emoji: fields[2] as String,
      appNames: (fields[3] as List).cast<String>(),
      durationMinutes: fields[4] as int,
      isActive: fields[5] as bool,
      activatedAtMs: fields[6] as int?,
    );
  }

  @override
  void write(BinaryWriter writer, Bloqueo obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.emoji)
      ..writeByte(3)
      ..write(obj.appNames)
      ..writeByte(4)
      ..write(obj.durationMinutes)
      ..writeByte(5)
      ..write(obj.isActive)
      ..writeByte(6)
      ..write(obj.activatedAtMs);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BloqueoAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
