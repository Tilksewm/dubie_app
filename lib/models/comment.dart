import 'package:hive/hive.dart';
import 'package:json_annotation/json_annotation.dart';

import 'debt.dart';

part 'comment.g.dart';

@HiveType(typeId: 3)
@JsonSerializable()
class Comment {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String commentText;
  @HiveField(2)
  final String commenterId;
  @HiveField(4)
  final String date; // Maps to 'created_at' in backend
  @HiveField(5)
  SyncStatus syncStatus;
  @HiveField(6)
  String debtId;

  Comment({
    required this.id,
    required this.commentText,
    required this.commenterId,
    required this.date,
    required this.syncStatus,
    required this.debtId
  });

  factory Comment.fromJson(Map<String, dynamic> json) => _$CommentFromJson(json);
  Map<String, dynamic> toJson() => _$CommentToJson(this);
}