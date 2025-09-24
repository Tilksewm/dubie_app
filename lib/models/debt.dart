import 'package:hive/hive.dart';
import 'package:json_annotation/json_annotation.dart';

part 'debt.g.dart';

@HiveType(typeId: 1)
@JsonSerializable()
class Debt extends HiveObject {
  @HiveField(0)
  String id;
  @HiveField(1)
  SyncStatus syncStatus;
  @HiveField(2)
  String creditorId;
  @HiveField(3)
  String borrowerId;
  @HiveField(4)
  String? overallDescription;
  @HiveField(5)
  bool isVerified;
  @HiveField(6)
  String status;
  @HiveField(7)
  String createdAt;
  @HiveField(8)
  String updatedAt;
  @HiveField(9)
  String? createdBy;

  // No DebtItem list here! The relationship is handled by the provider.

  Debt({
    required this.id,
    required this.creditorId,
    required this.borrowerId,
    this.overallDescription,
    this.isVerified = false,
    required this.status,
    this.syncStatus = SyncStatus.synced,
    required this.createdAt,
    required this.updatedAt,
    this.createdBy,
  });

  factory Debt.fromJson(Map<String, dynamic> json) => _$DebtFromJson(json);
  Map<String, dynamic> toJson() => _$DebtToJson(this);
}

@HiveType(typeId: 4)
enum SyncStatus {
  @HiveField(0)
  synced,
  @HiveField(1)
  created,
  @HiveField(2)
  updated,
  @HiveField(3)
  deleted,
}
// import 'package:json_annotation/json_annotation.dart';
//
// part 'debt.g.dart';
//
// @JsonSerializable()
// class DebtItem {
//   @JsonKey(name: 'item_id')
//   final String id;
//   final String description;
//   final double price; // Maps to 'amount' in backend
//   @JsonKey(name: 'paid_amount')
//   final double paidAmount;
//   @JsonKey(name: 'is_paid')
//   final bool isPaid;
//
//   DebtItem({
//     required this.id,
//     required this.description,
//     required this.price,
//     required this.paidAmount,
//     required this.isPaid,
//   });
//
//   factory DebtItem.fromJson(Map<String, dynamic> json) => _$DebtItemFromJson(json);
//   Map<String, dynamic> toJson() => _$DebtItemToJson(this);
// }
//
// @JsonSerializable()
// class Debt {
//   @JsonKey(name: 'debt_id')
//   final String id;
//   @JsonKey(name: 'creditor_id')
//   final String creditorId;
//   @JsonKey(name: 'borrower_id')
//   final String borrowerId;
//   @JsonKey(name: 'overall_description')
//   final String? overallDescription;
//   @JsonKey(name: 'is_verified')
//   final bool isVerified;
//   final String status; // 'new', 'pending_acceptance', 'accepted', 'amended_pending_reacceptance', 'rejected'
//   @JsonKey(name: 'created_at')
//   final DateTime createdAt;
//   @JsonKey(name: 'updated_at')
//   final DateTime updatedAt;
//
//   // These fields are expected by the frontend when fetching a full debt object
//   @JsonKey(name: 'total_amount')
//   final double? totalAmount;
//   @JsonKey(name: 'total_paid')
//   final double? totalPaid;
//   @JsonKey(name: 'outstanding_amount')
//   final double? outstandingAmount;
//   @JsonKey(name: 'creditor_name')
//   final String? creditorName;
//   @JsonKey(name: 'borrower_name')
//   final String? borrowerName;
//   final List<DebtItem>? items;
//
//   Debt({
//     required this.id,
//     required this.creditorId,
//     required this.borrowerId,
//     this.overallDescription,
//     required this.isVerified,
//     required this.status,
//     required this.createdAt,
//     required this.updatedAt,
//     this.totalAmount,
//     this.totalPaid,
//     this.outstandingAmount,
//     this.creditorName,
//     this.borrowerName,
//     this.items,
//   });
//
//   factory Debt.fromJson(Map<String, dynamic> json) => _$DebtFromJson(json);
//   Map<String, dynamic> toJson() => _$DebtToJson(this);
//
//   // Keep the copyWith method if you added it, it's generally useful
//   Debt copyWith({
//     String? id,
//     String? creditorId,
//     String? borrowerId,
//     String? overallDescription,
//     bool? isVerified,
//     String? status,
//     DateTime? createdAt,
//     DateTime? updatedAt,
//     double? totalAmount,
//     double? totalPaid,
//     double? outstandingAmount,
//     String? creditorName,
//     String? borrowerName,
//     List<DebtItem>? items,
//   }) {
//     return Debt(
//       id: id ?? this.id,
//       creditorId: creditorId ?? this.creditorId,
//       borrowerId: borrowerId ?? this.borrowerId,
//       overallDescription: overallDescription ?? this.overallDescription,
//       isVerified: isVerified ?? this.isVerified,
//       status: status ?? this.status,
//       createdAt: createdAt ?? this.createdAt,
//       updatedAt: updatedAt ?? this.updatedAt,
//       totalAmount: totalAmount ?? this.totalAmount,
//       totalPaid: totalPaid ?? this.totalPaid,
//       outstandingAmount: outstandingAmount ?? this.outstandingAmount,
//       creditorName: creditorName ?? this.creditorName,
//       borrowerName: borrowerName ?? this.borrowerName,
//       items: items ?? this.items,
//     );
//   }
// }
