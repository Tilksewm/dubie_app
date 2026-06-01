class CashTransaction {
  final String id;
  final String reason;
  final double amount;
  final String type;

  CashTransaction({
    required this.id,
    required this.reason,
    required this.amount,
    required this.type,
  });

  factory CashTransaction.fromJson(
      Map<String, dynamic> json) {
    return CashTransaction(
      id: json['id'],
      reason: json['reason'],
      amount: (json['amount'] as num).toDouble(),
      type: json['type'],
    );
  }
}
