
import 'package:dubie_app/l10n/app_localizations.dart';
import 'package:dubie_app/providers/debt_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class EditDebtForm extends StatefulWidget {
  final DebtThread debtThread;

  const EditDebtForm({
    super.key,
    required this.debtThread,
  });

  @override
  State<EditDebtForm> createState() => _EditDebtFormState();
}

class _EditDebtFormState extends State<EditDebtForm> {
  late TextEditingController _descController;
  late String _originalDesc;
  late List<_DebtItemModel> _editableItems;

  @override
  void initState() {
    super.initState();
    _originalDesc = widget.debtThread.debt.overallDescription ?? "";
    _descController = TextEditingController(text: _originalDesc);

    _editableItems = widget.debtThread.items
        .map((item) => _DebtItemModel(
      id: item.id,
      originalDescription: item.description,
      originalPrice: item.amount.toString(),
      originalPaidAmount: item.paidAmount.toString(),
      description: TextEditingController(text: item.description),
      price: TextEditingController(text: item.amount.toString()),
      paidAmount: TextEditingController(text: item.paidAmount.toString()),
    ))
        .toList();
  }

  Future<void> _handleSave() async {

    for (final item in _editableItems) {
      final debtItem = widget.debtThread.items.firstWhere((e) => e.id == item.id);
      if (item.deleted) {
        debtItem.updatedAt = DateTime.now().toIso8601String();
        await Provider.of<DebtProvider>(context, listen: false).deleteDebtItem(debtItem);
        
      } else if (item.isChanged()) {
        debtItem.description = item.description.text;
        debtItem.amount = double.tryParse(item.price.text) ?? 0;
        debtItem.paidAmount = double.tryParse(item.paidAmount.text) ?? 0;
        debtItem.updatedAt = DateTime.now().toIso8601String();
        await Provider.of<DebtProvider>(context, listen: false).updateDebtItem(debtItem);
      }
    }
    if(isDescUpdated()){
      final debt = widget.debtThread.debt;
      debt.overallDescription = _descController.text;
      await Provider.of<DebtProvider>(context, listen: false).updateDebt(debt);
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Title
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              color: Colors.blue,
            ),
            child: Text(
              loc.edit,
              style: const TextStyle(
                  fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ),

          // Scrollable body
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(loc.description,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _descController,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: loc.enterDescription,
                    ),
                  ),
                  const SizedBox(height: 16),

                  Text(loc.dubieItems,
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),

                  Column(
                    children: _editableItems.map((item) {
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: item.deleted
                              ? Colors.red.withOpacity(0.2)
                              : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: item.deleted ? Colors.red : Colors.grey),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: TextField(
                                controller: item.description,
                                enabled: !item.deleted,
                                decoration: InputDecoration(
                                    labelText: loc.description),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              flex: 2,
                              child: TextField(
                                controller: item.price,
                                enabled: !item.deleted,
                                keyboardType:
                                const TextInputType.numberWithOptions(
                                    decimal: true),
                                decoration: InputDecoration(
                                    labelText: loc.price),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              flex: 2,
                              child: TextField(
                                controller: item.paidAmount,
                                enabled: !item.deleted,
                                keyboardType:
                                const TextInputType.numberWithOptions(
                                    decimal: true),
                                decoration: InputDecoration(
                                    labelText: loc.paid),
                              ),
                            ),
                            IconButton(
                              icon: Icon(
                                item.deleted ? Icons.undo : Icons.delete,
                                color: item.deleted ? Colors.green : Colors.red,
                              ),
                              onPressed: () {
                                setState(() {
                                  item.deleted = !item.deleted;
                                });
                              },
                            )
                          ],
                        ),
                      );
                    }).toList(),
                  )
                ],
              ),
            ),
          ),

          // Fixed buttons
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius:
              const BorderRadius.vertical(bottom: Radius.circular(16)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(loc.cancel)),
                const SizedBox(width: 12),
                ElevatedButton(
                    onPressed: _handleSave, child: Text(loc.save)),
              ],
            ),
          )
        ],
      ),
    );
  }
  bool isDescUpdated(){
    return _descController.text != _originalDesc;
  }
}

class _DebtItemModel {
  final String id;

  final String originalDescription;
  final String originalPrice;
  final String originalPaidAmount;

  final TextEditingController description;
  final TextEditingController price;
  final TextEditingController paidAmount;
  bool deleted = false;

  _DebtItemModel({
    required this.id,
    required this.originalDescription,
    required this.originalPrice,
    required this.originalPaidAmount,
    required this.description,
    required this.price,
    required this.paidAmount,
  });

  bool isChanged() {
    return description.text != originalDescription ||
        price.text != originalPrice ||
        paidAmount.text != originalPaidAmount;
  }
}


// Usage
void showEditDebtForm (BuildContext context, DebtThread debtThread){
  showDialog(
    context: context,
    builder: (_) => SizedBox(
      width: MediaQuery.of(context).size.width * 0.9,
      height: MediaQuery.of(context).size.height * 0.7,
      child: EditDebtForm(debtThread: debtThread),
    ),
  );
}
