import 'package:dubie_app/core/custom_colors.dart';
import 'package:dubie_app/l10n/app_localizations.dart';
import 'package:dubie_app/models/debt.dart';
import 'package:dubie_app/models/debt_item.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dubie_app/providers/debt_provider.dart';
import 'package:dubie_app/services/api_service.dart';
import 'package:uuid/uuid.dart';

import '../models/user.dart';
import '../widgets/debt_participant_switch.dart'; // For ApiException

class CreateDebtScreen extends StatefulWidget {
  final User initialBorrower;
  final User initialCreditor;

  const CreateDebtScreen({
    super.key,
    required this.initialBorrower,
    required this.initialCreditor,
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
  final List<Map<String, dynamic>> _debtItems = [];

  User get initialCreditor => widget.initialCreditor;
  User get initialBorrower => widget.initialBorrower;

  late String _creditorId;
  late String _borrowerId;


  @override
  void initState() {
    super.initState();
    _creditorId = widget.initialCreditor.id;
    _borrowerId = widget.initialBorrower.id;
    _selectedBorrowerId = widget.initialBorrower.id;
    _selectedBorrowerName = widget.initialBorrower.name;
    _borrowerNameController.text = widget.initialBorrower.name;
    }
    void onSwitch({required String creditorId, required String borrowerId}) {
    setState(() {
      _creditorId = creditorId;
      _borrowerId = borrowerId;
    });
    print('Switched! New Creditor: $_creditorId, New Borrower: $_borrowerId');
  }

  void _addItem() {
    final loc = AppLocalizations.of(context)!;
    if (_itemDescriptionController.text.isEmpty || _itemPriceController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc.enterItemDescriptionAndPrice),
          backgroundColor: Theme.of(context).colorScheme.withdrawColor,),
      );
      return;
    }

    final double? price = double.tryParse(_itemPriceController.text);
    if (price == null || price <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc.enterValidPositivePrice),
          backgroundColor: Theme.of(context).colorScheme.withdrawColor,),
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
    final loc = AppLocalizations.of(context)!;
    if (_formKey.currentState!.validate() && _selectedBorrowerId != null && _debtItems.isNotEmpty) {
      setState(() {
        _isLoading = true;
      });
      try {
        String debtId = Uuid().v4();
        final debtProvider = Provider.of<DebtProvider>(context, listen: false);
        Debt newDebt = Debt(
          id: debtId,
          creditorId: _creditorId,
          borrowerId: _borrowerId,
          overallDescription: _overallDescriptionController.text,
          status: debtProvider.currentUserId! != _creditorId ? "accepted" : "new",
          createdAt: DateTime.now().toIso8601String(),
          updatedAt: DateTime.now().toIso8601String(),
          createdBy: debtProvider.currentUserId! != _creditorId ? "borrower" : null,
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
            SnackBar(content: Text(loc.debtCreatedSuccessfully)),
          );
          Navigator.of(context).pop(true); // Pop with true to indicate success
        }
      } on ApiException catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(loc.failedToCreateDebt),
              backgroundColor: Theme.of(context).colorScheme.withdrawColor,),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(loc.somethingWentWrong),
              backgroundColor: Theme.of(context).colorScheme.withdrawColor,),
          );
        }
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    } else if (_selectedBorrowerId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
         SnackBar(content: Text('Please select or search for a borrower.'),
          backgroundColor: Theme.of(context).colorScheme.withdrawColor,),
      );
    } else if (_debtItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc.addAtListOneItem),
          backgroundColor: Theme.of(context).colorScheme.withdrawColor,),
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
    final loc = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(loc.createNewDubie),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DebtParticipantSwitch(
                  initialGiver: initialCreditor,
                  initialBorrower: initialBorrower,
                  onSwitch: onSwitch
              ),
              const SizedBox(height: 16.0),
              TextFormField(
                controller: _overallDescriptionController,
                decoration: InputDecoration(
                  labelText: loc.overallDescriptionOptional,
                  border: const OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 24.0),
              Text(loc.addDubieItems, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16.0),
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: TextFormField(
                      controller: _itemDescriptionController,
                      decoration: InputDecoration(
                        labelText: loc.itemDescription,
                        border: const OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8.0),
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: _itemPriceController,
                      decoration: InputDecoration(
                        labelText: loc.price,
                        border: const OutlineInputBorder(),
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
                      trailing: Text('${loc.etb} ${item['price'].toStringAsFixed(2)}'),
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
                }),
              const SizedBox(height: 24.0),
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                onPressed: _createDebt,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: Text(loc.createDubie, style: const TextStyle(fontSize: 18)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}