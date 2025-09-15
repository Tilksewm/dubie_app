import 'package:hive/hive.dart';
import 'package:json_annotation/json_annotation.dart';

import 'debt.dart';

part 'comment.g.dart';

@HiveType(typeId: 3)
@JsonSerializable()
class Comment extends HiveObject {
  @HiveField(0)
  String id;
  @HiveField(1)
  String commentText;
  @HiveField(2)
  String userId;
  @HiveField(3)
  String createdAt; // Maps to 'created_at' in backend
  @HiveField(4)
  SyncStatus syncStatus;
  @HiveField(5)
  String debtId;

  Comment({
    required this.id,
    required this.commentText,
    required this.userId,
    required this.createdAt,
    this.syncStatus = SyncStatus.synced,
    required this.debtId
  });

  factory Comment.fromJson(Map<String, dynamic> json) => _$CommentFromJson(json);
  Map<String, dynamic> toJson() => _$CommentToJson(this);
}