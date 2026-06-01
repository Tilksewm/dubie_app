class CashTransactionCard extends StatelessWidget {
  final CashTransaction transaction;

  const CashTransactionCard({
    super.key,
    required this.transaction,
  });

  @override
  Widget build(BuildContext context) {
    final isDeposit =
        transaction.type == 'deposit';

    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 8,
      ),
      child: ListTile(
        title: Text(transaction.reason),
        trailing: Text(
          '${isDeposit ? '+' : '-'}ETB ${transaction.amount}',
          style: TextStyle(
            color:
                isDeposit ? Colors.green : Colors.red,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
