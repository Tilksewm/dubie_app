import 'package:json_annotation/json_annotation.dart';

part 'home_user.g.dart';
@JsonSerializable()
class HomeUser {
  final String userId;
  final String? name;
  final double totalAmount;
  final String type;
  final List<String> recentItems;

  HomeUser({
    required this.userId,
    this.name,
    required this.totalAmount,
    required this.type,
    required this.recentItems,
  });
  factory HomeUser.fromJson(Map<String, dynamic> json) => _$HomeUserFromJson(json);

  Map<String, dynamic> toJson() => _$HomeUserToJson(this);
}