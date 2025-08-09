import 'package:flutter/material.dart';

class EditDebtForm extends StatefulWidget {
  final Map<String, dynamic> description;
  // { "id": "desc1", "value": "Current description" }
  final List<Map<String, dynamic>> items;
  // [ { "id": "i1", "description": "...", "price": 100.0, "paidAmount": 50.0 } ]
  final Function(Map<String, dynamic> result) onSave;

  const EditDebtForm({
    super.key,
    required this.description,
    required this.items,
    required this.onSave,
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
    _originalDesc = widget.description['value'];
    _descController = TextEditingController(text: _originalDesc);

    _editableItems = widget.items
        .map((e) => _DebtItemModel(
      id: e['id'],
      originalDescription: e['description'],
      originalPrice: e['price'].toString(),
      originalPaidAmount: e['paidAmount'].toString(),
      description: TextEditingController(text: e['description']),
      price: TextEditingController(text: e['price'].toString()),
      paidAmount: TextEditingController(text: e['paidAmount'].toString()),
    ))
        .toList();
  }

  void _handleSave() {
    final updated = <Map<String, dynamic>>[];
    var updatedDescription = {
      "id": widget.description['id'],
      "value": _descController.text,
    };

    for (final item in _editableItems) {
      if (item.deleted) {
        updated.add({
          "id": item.id,
          "description": "",
          "price": 0,
          "paidAmount": 0,
        });
      } else if (item.isChanged()) {
        updated.add({
          "id": item.id,
          "description": item.description.text,
          "price": double.tryParse(item.price.text) ?? 0,
          "paidAmount": double.tryParse(item.paidAmount.text) ?? 0,
        });
      }
    }
    if(!isDescUpdated()){
      updatedDescription["value"] = "";
    }

    final result = {
      "description": updatedDescription,
      "items": updated,
    };

    widget.onSave(result);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
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
            child: const Text(
              "Edit",
              style: TextStyle(
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
                  const Text("Description",
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _descController,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: "Enter description",
                    ),
                  ),
                  const SizedBox(height: 16),

                  const Text("Debt Items",
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
                                decoration: const InputDecoration(
                                    labelText: "Description"),
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
                                decoration:
                                const InputDecoration(labelText: "Price"),
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
                                decoration: const InputDecoration(
                                    labelText: "Paid"),
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
                    child: const Text("Cancel")),
                const SizedBox(width: 12),
                ElevatedButton(
                    onPressed: _handleSave, child: const Text("Save")),
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
void showEditDebtForm(
    BuildContext context, {
      required Map<String, dynamic> description,
      required List<Map<String, dynamic>> items,
      required Function(Map<String, dynamic>) onSave,
    }) {
  showDialog(
    context: context,
    builder: (_) => SizedBox(
      width: MediaQuery.of(context).size.width * 0.9,
      height: MediaQuery.of(context).size.height * 0.7,
      child: EditDebtForm(
        description: description,
        items: items,
        onSave: onSave,
      ),
    ),
  );
}
