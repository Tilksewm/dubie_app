// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'home_user.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

HomeUser _$HomeUserFromJson(Map<String, dynamic> json) => HomeUser(
      userId: json['userId'] as String,
      name: json['name'] as String?,
      totalAmount: (json['totalAmount'] as num).toDouble(),
      type: json['type'] as String,
      recentItems: (json['recentItems'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
    );

Map<String, dynamic> _$HomeUserToJson(HomeUser instance) => <String, dynamic>{
      'userId': instance.userId,
      'name': instance.name,
      'totalAmount': instance.totalAmount,
      'type': instance.type,
      'recentItems': instance.recentItems,
    };
