// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'debt.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DebtItem _$DebtItemFromJson(Map<String, dynamic> json) => DebtItem(
  id: json['item_id'] as String,
  description: json['description'] as String,
  price: (json['price'] as num).toDouble(),
  paidAmount: (json['paid_amount'] as num).toDouble(),
  isPaid: json['is_paid'] as bool,
);

Map<String, dynamic> _$DebtItemToJson(DebtItem instance) => <String, dynamic>{
  'item_id': instance.id,
  'description': instance.description,
  'price': instance.price,
  'paid_amount': instance.paidAmount,
  'is_paid': instance.isPaid,
};

Debt _$DebtFromJson(Map<String, dynamic> json) => Debt(
  id: json['debt_id'] as String,
  creditorId: json['creditor_id'] as String,
  borrowerId: json['borrower_id'] as String,
  overallDescription: json['overall_description'] as String?,
  isVerified: json['is_verified'] as bool,
  status: json['status'] as String,
  createdAt: DateTime.parse(json['created_at'] as String),
  updatedAt: DateTime.parse(json['updated_at'] as String),
  totalAmount: (json['total_amount'] as num?)?.toDouble(),
  totalPaid: (json['total_paid'] as num?)?.toDouble(),
  outstandingAmount: (json['outstanding_amount'] as num?)?.toDouble(),
  creditorName: json['creditor_name'] as String?,
  borrowerName: json['borrower_name'] as String?,
  items:
      (json['items'] as List<dynamic>?)
          ?.map((e) => DebtItem.fromJson(e as Map<String, dynamic>))
          .toList(),
);

Map<String, dynamic> _$DebtToJson(Debt instance) => <String, dynamic>{
  'debt_id': instance.id,
  'creditor_id': instance.creditorId,
  'borrower_id': instance.borrowerId,
  'overall_description': instance.overallDescription,
  'is_verified': instance.isVerified,
  'status': instance.status,
  'created_at': instance.createdAt.toIso8601String(),
  'updated_at': instance.updatedAt.toIso8601String(),
  'total_amount': instance.totalAmount,
  'total_paid': instance.totalPaid,
  'outstanding_amount': instance.outstandingAmount,
  'creditor_name': instance.creditorName,
  'borrower_name': instance.borrowerName,
  'items': instance.items,
};
