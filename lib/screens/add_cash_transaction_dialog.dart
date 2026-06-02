Future<void> _showTransactionDialog(
    String type) async {

  final reasonController =
      TextEditingController();

  final amountController =
      TextEditingController();

  await showDialog(
    context: context,
    builder: (ctx) {
      return AlertDialog(
        title: Text(
          type == 'deposit'
              ? 'Deposit'
              : 'Withdraw',
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: reasonController,
              decoration:
                  const InputDecoration(
                labelText: 'Reason',
              ),
            ),

            TextField(
              controller: amountController,
              keyboardType:
                  TextInputType.number,
              decoration:
                  const InputDecoration(
                labelText: 'Amount',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),

          ElevatedButton(
            onPressed: () async {
              await Provider.of<HomeProvider>(
                context,
                listen: false,
              ).addCashTransaction(
                reason:
                    reasonController.text,
                amount: double.parse(
                    amountController.text),
                type: type,
              );

              Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      );
    },
  );
}
