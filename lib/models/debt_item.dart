import 'package:hive/hive.dart';
import 'package:json_annotation/json_annotation.dart';

import 'debt.dart';

part 'debt_item.g.dart';

@HiveType(typeId: 2)
@JsonSerializable()
class DebtItem extends HiveObject {
  @HiveField(0)
  String id;
  @HiveField(1)
  SyncStatus syncStatus;
  @HiveField(2)
  String debtId; // This acts as the foreign key
  @HiveField(3)
  double amount;
  @HiveField(4)
  String description;
  @HiveField(5)
  double paidAmount;
  @HiveField(6)
  bool isPaid;
  @HiveField(7)
  String createdAt;
  @HiveField(8)
  String updatedAt;

  DebtItem({
    required this.id,
    required this.debtId,
    required this.amount,
    required this.description,
    this.paidAmount = 0,
    this.isPaid = false,
    this.syncStatus = SyncStatus.synced,
    required this.createdAt,
    required this.updatedAt,
  });

  factory DebtItem.fromJson(Map<String, dynamic> json) => _$DebtItemFromJson(json);
  Map<String, dynamic> toJson() => _$DebtItemToJson(this);
}