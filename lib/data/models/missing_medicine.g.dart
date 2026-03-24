// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'missing_medicine.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class MissingMedicineAdapter extends TypeAdapter<MissingMedicine> {
  @override
  final int typeId = 2;

  @override
  MissingMedicine read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return MissingMedicine(
      id: fields[0] as String,
      medicineName: fields[1] as String,
      manualAlternative: fields[2] as String?,
      reportedDate: fields[3] as DateTime?,
      requestCount: fields[4] as int,
    );
  }

  @override
  void write(BinaryWriter writer, MissingMedicine obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.medicineName)
      ..writeByte(2)
      ..write(obj.manualAlternative)
      ..writeByte(3)
      ..write(obj.reportedDate)
      ..writeByte(4)
      ..write(obj.requestCount);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MissingMedicineAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
