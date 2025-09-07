import 'package:dubie_app/models/debt.dart';
import 'package:dubie_app/models/debt_item.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dubie_app/providers/debt_provider.dart';
import 'package:dubie_app/services/api_service.dart';
import 'package:uuid/uuid.dart'; // For ApiException

class CreateDebtScreen extends StatefulWidget {
  final String? initialBorrowerId;
  final String? initialBorrowerName;

  const CreateDebtScreen({
    super.key,
    this.initialBorrowerId,
    this.initialBorrowerName,
  });

  @override
  State<CreateDebtScreen> createState() => _CreateDebtScreenState();
}

class _CreateDebtScreenState extends State<CreateDebtScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _overallDescriptionController = TextEditingController();
  final TextEditingController _borrowerNameController = TextEditingController(); // For searching/displaying
  final TextEditingController _itemDescriptionController = TextEditingController();
  final TextEditingController _itemPriceController = TextEditingController();

  String? _selectedBorrowerId;
  String? _selectedBorrowerName;// The actual ID of the borrower

  bool _isLoading = false;
  List<Map<String, dynamic>> _debtItems = [];

  @override
  void initState() {
    super.initState();
    if (widget.initialBorrowerId != null && widget.initialBorrowerName != null) {
      _selectedBorrowerId = widget.initialBorrowerId;
      _selectedBorrowerName = widget.initialBorrowerName;
      _borrowerNameController.text = widget.initialBorrowerName!;
    }
  }

  void _addItem() {
    if (_itemDescriptionController.text.isEmpty || _itemPriceController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter item description and price.')),
      );
      return;
    }

    final double? price = double.tryParse(_itemPriceController.text);
    if (price == null || price <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid positive price.')),
      );
      return;
    }

    setState(() {
      _debtItems.add({
        'description': _itemDescriptionController.text,
        'price': price,
      });
      _itemDescriptionController.clear();
      _itemPriceController.clear();
    });
  }

  Future<void> _createDebt() async {
    if (_formKey.currentState!.validate() && _selectedBorrowerId != null && _debtItems.isNotEmpty) {
      setState(() {
        _isLoading = true;
      });
      try {
        String debtId = Uuid().v4();
        final debtProvider = Provider.of<DebtProvider>(context, listen: false);
        Debt newDebt = Debt(
          id: debtId,
          creditorId: debtProvider.currentUserId!,
          borrowerId: _selectedBorrowerId!,
          overallDescription: _overallDescriptionController.text,
          status: "new",
          createdAt: DateTime.now().toIso8601String(),
          updatedAt: DateTime.now().toIso8601String(),
        );
        await debtProvider.dbService.addDebt(newDebt);
        for (var item in _debtItems) {
          DebtItem debtItem = DebtItem(
            id: Uuid().v4(),
            debtId: debtId,
            description: item['description'],
            amount: item['price'],
            paidAmount: 0.0,
            createdAt: DateTime.now().toIso8601String(),
            updatedAt: DateTime.now().toIso8601String(),
          );
          await debtProvider.dbService.addDebtItem(debtItem);
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Debt "${newDebt.id}" created successfully!')),
          );
          Navigator.of(context).pop(true); // Pop with true to indicate success
        }
      } on ApiException catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to create debt: ${e.message}')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('An unexpected error occurred.')),
          );
        }
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    } else if (_selectedBorrowerId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select or search for a borrower.')),
      );
    } else if (_debtItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one debt item.')),
      );
    }
  }

  @override
  void dispose() {
    _overallDescriptionController.dispose();
    _borrowerNameController.dispose();
    _itemDescriptionController.dispose();
    _itemPriceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create New Dubie'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Borrower Selection (Simplified for now)
              // In a real app, this would involve searching for users
              // or selecting from contacts. For now, it uses the initial
              // borrower or allows manual entry (which implies backend
              // search/creation when `_selectedBorrowerId` is null).
              // TextFormField(
              //   controller: _borrowerNameController,
              //   decoration: const InputDecoration(
              //     labelText: 'Borrower Name/Email/Phone',
              //     border: OutlineInputBorder(),
              //     hintText: 'e.g., John Doe or john@example.com',
              //   ),
              //   readOnly: widget.initialBorrowerId != null, // Make read-only if pre-selected
              //   validator: (value) {
              //     if (_selectedBorrowerId == null) {
              //       return 'Please select or search for a borrower.';
              //     }
              //     return null;
              //   },
              //   onTap: widget.initialBorrowerId == null
              //       ? () async {
              //     // TODO: Implement a proper user search/selection screen
              //     if (_selectedBorrowerId == null) {
              //       final result = await showDialog<String>(
              //         context: context,
              //         builder: (context) => AlertDialog(
              //           title: const Text('Enter Borrower ID (for testing)'),
              //           content: TextField(
              //             controller: _borrowerNameController, // Using this for input
              //             decoration: const InputDecoration(hintText: "Enter Name or User ID"),
              //           ),
              //           actions: [
              //             TextButton(
              //               onPressed: () {
              //                 Navigator.pop(context);
              //               },
              //               child: const Text('Cancel'),
              //             ),
              //             ElevatedButton(
              //               onPressed: () {
              //                 if (_borrowerNameController.text.isNotEmpty) {
              //                   _selectedBorrowerId = _borrowerNameController.text; // For testing, assume direct ID or search by name.
              //                   Navigator.pop(context, _borrowerNameController.text);
              //                 }
              //               },
              //               child: const Text('OK'),
              //             ),
              //           ],
              //         ),
              //       );
              //       if (result != null) {
              //         setState(() {
              //           _borrowerNameController.text = result; // Display name
              //         });
              //       }
              //     }
              //   }
              //       : null,
              // ),
              //const SizedBox(height: 16.0),
              TextFormField(
                controller: _overallDescriptionController,
                decoration: const InputDecoration(
                  labelText: 'Overall Description (Optional)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 24.0),
              const Text('Add Dubie Items:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16.0),
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: TextFormField(
                      controller: _itemDescriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Item Description',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8.0),
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: _itemPriceController,
                      decoration: const InputDecoration(
                        labelText: 'Price',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 8.0),
                  IconButton(
                    icon: const Icon(Icons.add_circle, color: Colors.green, size: 30),
                    onPressed: _addItem,
                  ),
                ],
              ),
              const SizedBox(height: 16.0),
              if (_debtItems.isNotEmpty)
                ..._debtItems.asMap().entries.map((entry) {
                  int idx = entry.key;
                  Map<String, dynamic> item = entry.value;
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    child: ListTile(
                      title: Text(item['description']),
                      trailing: Text('ETB ${item['price'].toStringAsFixed(2)}'),
                      leading: IconButton(
                        icon: const Icon(Icons.remove_circle, color: Colors.red),
                        onPressed: () {
                          setState(() {
                            _debtItems.removeAt(idx);
                          });
                        },
                      ),
                    ),
                  );
                }).toList(),
              const SizedBox(height: 24.0),
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                onPressed: _createDebt,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: const Text('Create Dubie', style: TextStyle(fontSize: 18)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}