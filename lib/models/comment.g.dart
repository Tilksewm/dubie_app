// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'comment.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class CommentAdapter extends TypeAdapter<Comment> {
  @override
  final int typeId = 3;

  @override
  Comment read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Comment(
      id: fields[0] as String,
      commentText: fields[1] as String,
      commenterId: fields[2] as String,
      date: fields[4] as String,
      syncStatus: fields[5] as SyncStatus,
      debtId: fields[6] as String,
    );
  }

  @override
  void write(BinaryWriter writer, Comment obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.commentText)
      ..writeByte(2)
      ..write(obj.commenterId)
      ..writeByte(4)
      ..write(obj.date)
      ..writeByte(5)
      ..write(obj.syncStatus)
      ..writeByte(6)
      ..write(obj.debtId);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CommentAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Comment _$CommentFromJson(Map<String, dynamic> json) => Comment(
      id: json['id'] as String,
      commentText: json['commentText'] as String,
      commenterId: json['commenterId'] as String,
      date: json['date'] as String,
      syncStatus: $enumDecode(_$SyncStatusEnumMap, json['syncStatus']),
      debtId: json['debtId'] as String,
    );

Map<String, dynamic> _$CommentToJson(Comment instance) => <String, dynamic>{
      'id': instance.id,
      'commentText': instance.commentText,
      'commenterId': instance.commenterId,
      'date': instance.date,
      'syncStatus': _$SyncStatusEnumMap[instance.syncStatus]!,
      'debtId': instance.debtId,
    };

const _$SyncStatusEnumMap = {
  SyncStatus.synced: 'synced',
  SyncStatus.created: 'created',
  SyncStatus.updated: 'updated',
  SyncStatus.deleted: 'deleted',
};
