// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

User _$UserFromJson(Map<String, dynamic> json) => User(
  id: json['id'] as String,
  email: json['email'] as String?,
  name: json['name'] as String,
  username: json['username'] as String?,
  phone: json['phone'] as String?,
  userType: json['user_type'] as String,
  createdAt: json['created_at'] == null
      ? null
      : DateTime.parse(json['created_at'] as String),
  updatedAt: json['updated_at'] == null
      ? null
      : DateTime.parse(json['updated_at'] as String),
);

Map<String, dynamic> _$UserToJson(User instance) => <String, dynamic>{
  'id': instance.id,
  'email': instance.email,
  'name': instance.name,
  'username': instance.username,
  'phone': instance.phone,
  'user_type': instance.userType,
  'created_at': instance.createdAt?.toIso8601String(),
  'updated_at': instance.updatedAt?.toIso8601String(),
};

HomeUser _$HomeUserFromJson(Map<String, dynamic> json) => HomeUser(
  userId: json['user_id'] as String,
  name: json['name'] as String?,
  totalAmount: (json['total_amount'] as num).toDouble(),
  connectionStatus: json['connection_status'] as String,
  recentItems: (json['recent_items'] as List<dynamic>)
      .map((e) => e as String)
      .toList(),
);

Map<String, dynamic> _$HomeUserToJson(HomeUser instance) => <String, dynamic>{
  'user_id': instance.userId,
  'name': instance.name,
  'total_amount': instance.totalAmount,
  'connection_status': instance.connectionStatus,
  'recent_items': instance.recentItems,
};
