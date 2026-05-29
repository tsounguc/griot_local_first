// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'griot_memory_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class GriotMemoryModelAdapter extends TypeAdapter<GriotMemoryModel> {
  @override
  final int typeId = 0;

  @override
  GriotMemoryModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return GriotMemoryModel(
      id: fields[0] as String,
      content: fields[1] as String,
      tags: (fields[2] as List).cast<String>(),
      createdAt: fields[3] as DateTime,
      updatedAt: fields[4] as DateTime,
      importance: fields[5] as double,
    );
  }

  @override
  void write(BinaryWriter writer, GriotMemoryModel obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.content)
      ..writeByte(2)
      ..write(obj.tags)
      ..writeByte(3)
      ..write(obj.createdAt)
      ..writeByte(4)
      ..write(obj.updatedAt)
      ..writeByte(5)
      ..write(obj.importance);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GriotMemoryModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
