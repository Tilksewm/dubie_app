// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'debt.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class DebtAdapter extends TypeAdapter<Debt> {
  @override
  final int typeId = 1;

  @override
  Debt read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Debt(
      id: fields[0] as String,
      creditorId: fields[2] as String,
      borrowerId: fields[3] as String,
      overallDescription: fields[4] as String?,
      isVerified: fields[5] as bool,
      status: fields[6] as String,
      syncStatus: fields[1] as SyncStatus,
      createdAt: fields[7] as String,
      updatedAt: fields[8] as String,
      createdBy: fields[9] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, Debt obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.syncStatus)
      ..writeByte(2)
      ..write(obj.creditorId)
      ..writeByte(3)
      ..write(obj.borrowerId)
      ..writeByte(4)
      ..write(obj.overallDescription)
      ..writeByte(5)
      ..write(obj.isVerified)
      ..writeByte(6)
      ..write(obj.status)
      ..writeByte(7)
      ..write(obj.createdAt)
      ..writeByte(8)
      ..write(obj.updatedAt)
      ..writeByte(9)
      ..write(obj.createdBy);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DebtAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class SyncStatusAdapter extends TypeAdapter<SyncStatus> {
  @override
  final int typeId = 4;

  @override
  SyncStatus read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return SyncStatus.synced;
      case 1:
        return SyncStatus.created;
      case 2:
        return SyncStatus.updated;
      case 3:
        return SyncStatus.deleted;
      default:
        return SyncStatus.synced;
    }
  }

  @override
  void write(BinaryWriter writer, SyncStatus obj) {
    switch (obj) {
      case SyncStatus.synced:
        writer.writeByte(0);
        break;
      case SyncStatus.created:
        writer.writeByte(1);
        break;
      case SyncStatus.updated:
        writer.writeByte(2);
        break;
      case SyncStatus.deleted:
        writer.writeByte(3);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SyncStatusAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Debt _$DebtFromJson(Map<String, dynamic> json) => Debt(
      id: json['id'] as String,
      creditorId: json['creditorId'] as String,
      borrowerId: json['borrowerId'] as String,
      overallDescription: json['overallDescription'] as String?,
      isVerified: json['isVerified'] as bool? ?? false,
      status: json['status'] as String,
      syncStatus:
          $enumDecodeNullable(_$SyncStatusEnumMap, json['syncStatus']) ??
              SyncStatus.synced,
      createdAt: json['createdAt'] as String,
      updatedAt: json['updatedAt'] as String,
      createdBy: json['createdBy'] as String?,
    );

Map<String, dynamic> _$DebtToJson(Debt instance) => <String, dynamic>{
      'id': instance.id,
      'syncStatus': _$SyncStatusEnumMap[instance.syncStatus]!,
      'creditorId': instance.creditorId,
      'borrowerId': instance.borrowerId,
      'overallDescription': instance.overallDescription,
      'isVerified': instance.isVerified,
      'status': instance.status,
      'createdAt': instance.createdAt,
      'updatedAt': instance.updatedAt,
      'createdBy': instance.createdBy,
    };

const _$SyncStatusEnumMap = {
  SyncStatus.synced: 'synced',
  SyncStatus.created: 'created',
  SyncStatus.updated: 'updated',
  SyncStatus.deleted: 'deleted',
};
