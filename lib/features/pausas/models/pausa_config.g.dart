// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pausa_config.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class PausaConfigAdapter extends TypeAdapter<PausaConfig> {
  @override
  final int typeId = 0;

  @override
  PausaConfig read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PausaConfig(
      appName: fields[0] as String,
      packageName: fields[1] as String,
      waitSeconds: fields[2] as int,
      maxMinutes: fields[3] as int,
      isActive: fields[4] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, PausaConfig obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.appName)
      ..writeByte(1)
      ..write(obj.packageName)
      ..writeByte(2)
      ..write(obj.waitSeconds)
      ..writeByte(3)
      ..write(obj.maxMinutes)
      ..writeByte(4)
      ..write(obj.isActive);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PausaConfigAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
