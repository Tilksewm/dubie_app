// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'debt_item.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class DebtItemAdapter extends TypeAdapter<DebtItem> {
  @override
  final int typeId = 2;

  @override
  DebtItem read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return DebtItem(
      id: fields[0] as String,
      debtId: fields[2] as String,
      amount: fields[3] as double,
      description: fields[4] as String,
      paidAmount: fields[5] as double,
      isPaid: fields[6] as bool,
      syncStatus: fields[1] as SyncStatus,
      createdAt: fields[7] as String,
      updatedAt: fields[8] as String,
    );
  }

  @override
  void write(BinaryWriter writer, DebtItem obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.syncStatus)
      ..writeByte(2)
      ..write(obj.debtId)
      ..writeByte(3)
      ..write(obj.amount)
      ..writeByte(4)
      ..write(obj.description)
      ..writeByte(5)
      ..write(obj.paidAmount)
      ..writeByte(6)
      ..write(obj.isPaid)
      ..writeByte(7)
      ..write(obj.createdAt)
      ..writeByte(8)
      ..write(obj.updatedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DebtItemAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DebtItem _$DebtItemFromJson(Map<String, dynamic> json) => DebtItem(
      id: json['id'] as String,
      debtId: json['debtId'] as String,
      amount: (json['amount'] as num).toDouble(),
      description: json['description'] as String,
      paidAmount: (json['paidAmount'] as num).toDouble(),
      isPaid: json['isPaid'] as bool,
      syncStatus:
          $enumDecodeNullable(_$SyncStatusEnumMap, json['syncStatus']) ??
              SyncStatus.synced,
      createdAt: json['createdAt'] as String,
      updatedAt: json['updatedAt'] as String,
    );

Map<String, dynamic> _$DebtItemToJson(DebtItem instance) => <String, dynamic>{
      'id': instance.id,
      'syncStatus': _$SyncStatusEnumMap[instance.syncStatus]!,
      'debtId': instance.debtId,
      'amount': instance.amount,
      'description': instance.description,
      'paidAmount': instance.paidAmount,
      'isPaid': instance.isPaid,
      'createdAt': instance.createdAt,
      'updatedAt': instance.updatedAt,
    };

const _$SyncStatusEnumMap = {
  SyncStatus.synced: 'synced',
  SyncStatus.created: 'created',
  SyncStatus.updated: 'updated',
  SyncStatus.deleted: 'deleted',
};
