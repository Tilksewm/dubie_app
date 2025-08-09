// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'comment.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Comment _$CommentFromJson(Map<String, dynamic> json) => Comment(
  id: json['comment_id'] as String,
  commentText: json['comment'] as String,
  commenterId: json['commenter_id'] as String,
  commenterName: json['commenter_name'] as String?,
  date: DateTime.parse(json['date'] as String),
);

Map<String, dynamic> _$CommentToJson(Comment instance) => <String, dynamic>{
  'comment_id': instance.id,
  'comment': instance.commentText,
  'commenter_id': instance.commenterId,
  'commenter_name': instance.commenterName,
  'date': instance.date.toIso8601String(),
};
