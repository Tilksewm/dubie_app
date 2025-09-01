import 'package:dubie_app/models/debt.dart';
import 'package:hive/hive.dart';
import 'package:json_annotation/json_annotation.dart';

part 'user.g.dart'; // This file will be generated automatically

@HiveType(typeId: 0)
@JsonSerializable()
class User extends HiveObject {
  @HiveField(0)
  String id;
  @HiveField(1)
  SyncStatus syncStatus;
  @HiveField(2)
  String? email;
  @HiveField(3)
  String name;
  @HiveField(4)
  String? username;
  @HiveField(5)
  String? phone;
  @HiveField(6)
  String userType; // 'real', 'placeholder', 'temporary'
  @HiveField(7)
  String createdAt;
  @HiveField(8)
  String updatedAt;

  User({
    required this.id,
    this.syncStatus = SyncStatus.synced,
    this.email,
    required this.name,
    this.username,
    this.phone,
    required this.userType,
    required this.createdAt,
    required this.updatedAt,
  });

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);

  Map<String, dynamic> toJson() => _$UserToJson(this);
}
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
}
/*
  User copyWith({
    String? id,
    String? email,
    String? name,
    String? username,
    String? phone,
    String? userType,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      username: username ?? this.username,
      phone: phone ?? this.phone,
      userType: userType ?? this.userType,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

// For home_users API, which is a simplified user view
@JsonSerializable()
class HomeUser {
  @JsonKey(name: 'user_id')
  final String userId;
  final String? name;
  @JsonKey(name: 'total_amount')
  final double totalAmount;
  @JsonKey(name: 'connection_status')
  final String connectionStatus;
  @JsonKey(name: 'recent_items')
  final List<String> recentItems;

  HomeUser({
    required this.userId,
    this.name,
    required this.totalAmount,
    required this.connectionStatus,
    required this.recentItems,
  });

  factory HomeUser.fromJson(Map<String, dynamic> json) => _$HomeUserFromJson(json);
  Map<String, dynamic> toJson() => _$HomeUserToJson(this);

  HomeUser copyWith({
    String? userId,
    String? name,
    double? totalAmount,
    String? connectionStatus,
    List<String>? recentItems,
  }) {
    return HomeUser(
      userId: userId ?? this.userId,
      name: name ?? this.name,
      totalAmount: totalAmount ?? this.totalAmount,
      connectionStatus: connectionStatus ?? this.connectionStatus,
      recentItems: recentItems ?? this.recentItems,
    );
  }
}
*/
// import 'package:json_annotation/json_annotation.dart';
//
// part 'user.g.dart'; // This file will be generated automatically
//
// @JsonSerializable()
// class User {
//   final String id;
//   final String? email;
//   final String name;
//   final String? username;
//   final String? phone;
//   @JsonKey(name: 'user_type')
//   final String userType; // 'real', 'placeholder', 'temporary'
//   @JsonKey(name: 'created_at')
//   final DateTime? createdAt;
//   @JsonKey(name: 'updated_at')
//   final DateTime? updatedAt;
//
//   User({
//     required this.id,
//     this.email,
//     required this.name,
//     this.username,
//     this.phone,
//     required this.userType,
//     this.createdAt,
//     this.updatedAt,
//   });
//
//   factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
//   Map<String, dynamic> toJson() => _$UserToJson(this);
// }
//
// // For home_users API, which is a simplified user view
// @JsonSerializable()
// class HomeUser {
//   @JsonKey(name: 'user_id')
//   final String userId;
//   final String? name;
//   @JsonKey(name: 'total_amount')
//   final double totalAmount;
//   @JsonKey(name: 'connection_status')
//   final String connectionStatus;
//   @JsonKey(name: 'recent_items')
//   final List<String> recentItems;
//
//   HomeUser({
//     required this.userId,
//     this.name,
//     required this.totalAmount,
//     required this.connectionStatus,
//     required this.recentItems,
//   });
//
//   factory HomeUser.fromJson(Map<String, dynamic> json) => _$HomeUserFromJson(json);
//   Map<String, dynamic> toJson() => _$HomeUserToJson(this);
// }