import 'package:json_annotation/json_annotation.dart';

part 'comment.g.dart';

@JsonSerializable()
class Comment {
  @JsonKey(name: 'comment_id')
  final String id;
  @JsonKey(name: 'comment')
  final String commentText;
  @JsonKey(name: 'commenter_id')
  final String commenterId;
  @JsonKey(name: 'commenter_name')
  final String? commenterName; // Joined from user table
  final DateTime date; // Maps to 'created_at' in backend

  Comment({
    required this.id,
    required this.commentText,
    required this.commenterId,
    this.commenterName,
    required this.date,
  });

  factory Comment.fromJson(Map<String, dynamic> json) => _$CommentFromJson(json);
  Map<String, dynamic> toJson() => _$CommentToJson(this);
}