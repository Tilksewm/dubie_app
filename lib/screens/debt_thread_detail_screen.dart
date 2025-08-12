import 'dart:ffi';

import 'package:dubie_app/screens/user_debts_detail_screen.dart';
import 'package:dubie_app/widgets/edit_debt_form.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import 'package:dubie_app/providers/debt_provider.dart';
import 'package:dubie_app/services/api_service.dart';

import '../models/debt.dart'; // For ApiException

class DebtThreadDetailScreen extends StatefulWidget {
  final String debtId;
  final String? otherUserName; // Passed for AppBar title

  const DebtThreadDetailScreen({
    super.key,
    required this.debtId,
    this.otherUserName,
  });

  @override
  State<DebtThreadDetailScreen> createState() => _DebtThreadDetailScreenState();
}

class _DebtThreadDetailScreenState extends State<DebtThreadDetailScreen> {
  final TextEditingController _commentController = TextEditingController();
  final TextEditingController _itemDescriptionController = TextEditingController();
  final TextEditingController _itemPriceController = TextEditingController();

  final NumberFormat currencyFormatter = NumberFormat.currency(
    locale: 'en_US',
    symbol: 'ETB ',
    decimalDigits: 2,
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<DebtProvider>(context, listen: false).fetchDebtDetails(widget.debtId);
    });
  }
  void _debtOnSave (Map<String, dynamic> result) async{
    // i will add calling the back end to update descriptions and iteratively update every changed items
    print("Save called with: $result");
    final description = result["description"];
    final debts = result["items"];
    if (description["value"] != ""){
      //print()
      await Provider.of<DebtProvider>(context, listen: false)
          .updateDebtDescription(description["id"],  description["value"]);
      print("print description value: ${description.value}");
    }
    for (var debtItem in debts){
      if (debtItem["description"] != "" && debtItem["price"] != 0){
        await Provider.of<DebtProvider>(context, listen: false).updateDebtItem(
            widget.debtId,
            debtItem["id"],
            description: debtItem["description"],
            price: debtItem["price"],
            paidAmount: debtItem["paidAmount"]
        );
      }else if (debtItem["description"] == "" && debtItem["price"] == 0){
        await Provider.of<DebtProvider>(context, listen: false).deleteDebtItem(
          widget.debtId, debtItem["id"]
        );
      }
    }
  }
  void _updateDebt (BuildContext context, Debt debt){
    Map<String, dynamic> description = {"id":debt.id, "value":debt.overallDescription ?? ""};
    List<Map<String, dynamic>> debtItems = debt.items!.map((item) => {
      "id": item.id,
      "description": item.description,
      "price": item.price,
      "paidAmount": item.paidAmount,
    }).toList();
    showDialog(
        context: context,
        builder: (_) => SizedBox(
          width: MediaQuery.of(context).size.width * 0.9,
          height: MediaQuery.of(context).size.height * 0.7,
          child: EditDebtForm(description: description, items: debtItems, onSave: _debtOnSave),
        )
    );
  }
  Future<void> _deleteDebt(BuildContext context, String debtId) async {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Debt'),
        content: const Text('Are you sure you want to delete this Debt? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              // Implement delete debt logic here
              // This usually involves an API call to your backend
              // Then log out the user and navigate to login screen
              // For now, just log out as a placeholder
              try {
                await Provider.of<DebtProvider>(context, listen: false).deleteDebt(debtId);
                
                if (mounted) {
                  Navigator.of(ctx).pop(); // Pop dialog
                  Navigator.of(context).pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Debt deleted successfully.')),
                  );
                }
              } catch (e) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  SnackBar(content: Text('Failed to delete Debt: $e')),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
  Future<void> _refreshDebtDetails() async {
    await Provider.of<DebtProvider>(context, listen: false).fetchDebtDetails(widget.debtId);
  }

  Future<void> _addComment() async {
    if (_commentController.text.isEmpty) return;
    try {
      await Provider.of<DebtProvider>(context, listen: false)
          .addComment(widget.debtId, _commentController.text);
      _commentController.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Comment added!')),
        );
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add comment: ${e.message}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('An unexpected error occurred.')),
        );
      }
    }
  }

  Future<void> _addDebtItem() async {
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

    try {
      await Provider.of<DebtProvider>(context, listen: false).addDebtItem(
        widget.debtId,
        description: _itemDescriptionController.text,
        price: price,
      );
      _itemDescriptionController.clear();
      _itemPriceController.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Item added!')),
        );
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add item: ${e.message}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('An unexpected error occurred.')),
        );
      }
    }
  }

  Future<void> _payDebtItemForm(String itemId, double currentPaidAmount, double itemPrice) async {
    final TextEditingController amountController = TextEditingController(text: '${itemPrice - currentPaidAmount}');
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Record Payment'),
        content: TextField(
          controller: amountController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: 'Amount Paid (Max: ${currencyFormatter.format(itemPrice - currentPaidAmount)})',
            hintText: 'Enter amount to pay',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final double? amount = double.tryParse(amountController.text);
              if (amount == null || amount <= 0 || (currentPaidAmount + amount) > itemPrice) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter a valid amount.')),
                  );
                }
                return;
              }
              _payDebtItem(widget.debtId, itemId, amount);
              Navigator.pop(context); // Close dialog
              //
              // try {
              //   await Provider.of<DebtProvider>(context, listen: false).payDebtItem(
              //     widget.debtId,
              //     itemId,
              //     amount,
              //   );
              //   //_refreshDebtDetails();
              //   if (mounted) {
              //     ScaffoldMessenger.of(context).showSnackBar(
              //       const SnackBar(content: Text('Payment recorded!')),
              //     );
              //   }
              //
              // } on ApiException catch (e) {
              //   if (mounted) {
              //     ScaffoldMessenger.of(context).showSnackBar(
              //       SnackBar(content: Text('Failed to record payment: ${e.message}')),
              //     );
              //   }
              // } catch (e) {
              //   if (mounted) {
              //     ScaffoldMessenger.of(context).showSnackBar(
              //       const SnackBar(content: Text('An unexpected error occurred.')),
              //     );
              //   }
              // }
            },
            child: const Text('Pay'),
          ),
        ],
      ),
    );
  }
  Future <void> _payDebtItem(String debtId, String itemId, amount) async{
    try {
      await Provider.of<DebtProvider>(context, listen: false).payDebtItem(
        widget.debtId,
        itemId,
        amount,
      );
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to record payment: ${e.message}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('An unexpected error occurred.')),
        );
      }
    }
  }
  Future<void> _payRandomDebt(Debt debt, double totalAmount) async{
    if (totalAmount <= debt.outstandingAmount!){
      List<DebtItem> items = debt.items!;
      try{
        for (var item in items){
          if (totalAmount > 0){
            var itemOutstanding = item.price - item.paidAmount;
            if (totalAmount >= itemOutstanding){
              _payDebtItem(debt.id, item.id, itemOutstanding);
              totalAmount -= itemOutstanding;
            }else{
              _payDebtItem(debt.id, item.id, totalAmount);
              totalAmount = 0;
              break;
            }
          }else{ break;}
        }
        _refreshDebtDetails();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Payment recorded!')),
          );
        }
      }

      on ApiException catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to record payment: ${e.message}')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('An unexpected error occurred. $e')),
          );
        }
      }
    }else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Entered Amount Exceeded the outstanding Amount")
        )
      );
    }

    print("total payment: $totalAmount");
  }
  Future<void> _payAllForm(Debt debt) async {
    final TextEditingController totalPaymentController = TextEditingController(text: "${debt.outstandingAmount}");

    await showDialog(context: context, builder: (context) =>
      AlertDialog(
        title: Text("Enter Total Amount"),
        content: TextField(
              controller: totalPaymentController,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                labelText: "Amount Paid (Max: ${currencyFormatter.format(debt.outstandingAmount)}",
                hintText: "Enter Total Amount",
              )
          ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              _payRandomDebt(debt, double.parse(totalPaymentController.text));
              totalPaymentController.clear();
              Navigator.pop(context);
            },
            child: Text("Pay"),
          ),
        ],
      ),
    );
  }

  Future<void> _showAddItemDialog() async {
    _itemDescriptionController.clear();
    _itemPriceController.clear();
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Dubie Item'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _itemDescriptionController,
              decoration: const InputDecoration(labelText: 'Description'),
            ),
            TextField(
              controller: _itemPriceController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Amount'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              _addDebtItem();
              Navigator.pop(context); // Close dialog
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _commentController.dispose();
    _itemDescriptionController.dispose();
    _itemPriceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Consumer<DebtProvider>(
          builder: (context, debtProvider, child) {
            final debt = debtProvider.currentDebt;
            if (debtProvider.isLoadingDebt && debt == null) {
              return const Text('Loading Debt...');
            }
            final String titleText = debtProvider.currentDebt?.items?.length.toString() ?? debt?.overallDescription ?? 'Debt Details';
            final double outstanding = debt?.outstandingAmount ?? 0.0;
            final double totalAmount = debt?.totalAmount ?? 0.0;
            final double totalPaid = debt?.totalPaid ?? 0.0;
            final Color amountColor = outstanding >= 0 ? Colors.green.shade700 : Colors.red.shade700;
            final String amountPrefix = outstanding >= 0 ? '+' : ''; // No '-' for positive numbers

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("$titleText Items", style: const TextStyle(fontSize: 18)),
                Text(
                  'Paid: ${currencyFormatter.format(totalPaid.abs())} / $totalAmount',
                  style: TextStyle(fontSize: 14, color: Colors.black),
                ),
              ],
            );
          },
        ),
        actions: [
      Consumer<DebtProvider>(builder: (BuildContext context, DebtProvider value, Widget? child) {
        final Color amountColor = value.currentDebt!.outstandingAmount! >= 0 ? Colors.green.shade700 : Colors.red.shade700;
        return
          Padding(
            padding: EdgeInsets.fromLTRB(0,0, 30, 0),
              child:
              Column(
                children: [
                  Text(
                    'Outstanding',
                    style: TextStyle(fontSize: 14,),
                  ),
                  Text(
                    currencyFormatter.format(value.currentDebt?.outstandingAmount),
                    style: TextStyle(fontSize: 18,),
                  )
                ],
              )
        );
    },

      )

        ],
      ),
      body: Consumer<DebtProvider>(
        builder: (context, debtProvider, child) {
          if (debtProvider.isLoadingDebt && debtProvider.currentDebt == null) {
            return const Center(child: CircularProgressIndicator());
          }
          if (debtProvider.debtError != null) {
            return Center(child: Text('Error: ${debtProvider.debtError}'));
          }
          if (debtProvider.currentDebt == null) {
            return const Center(child: Text('Debt not found.'));
          }

          final debt = debtProvider.currentDebt!;
          final bool isCreditor = debt.creditorId == debtProvider.currentUserId;
          final bool isBorrower = debt.borrowerId == debtProvider.currentUserId;

          return RefreshIndicator(
            onRefresh: _refreshDebtDetails,
            child: Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(16.0),
                    children: [
                      // Debt Status and Actions
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Text(
                              //   'Debt ID: ${debt.id.substring(0, 8)}...',
                              //   style: const TextStyle(fontSize: 12, color: Colors.grey),
                              // ),
                              // const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Status: ${debt.status}',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: _getStatusColor(debt.status),
                                        ),
                                      ),
                                      if (debt.overallDescription != null && debt.overallDescription!.isNotEmpty)
                                        Padding(
                                          padding: const EdgeInsets.only(top: 8.0),
                                          child: Text('${debt.overallDescription}'),
                                        ),
                                    ],
                                  ),
                                  PopupMenuButton<String>(
                                    onSelected: (value) {
                                      if (value == 'edit') {
                                        _updateDebt(context, debt);
                                        print("Edit clicked");
                                      } else if (value == 'delete') {
                                        _deleteDebt(context, debt.id);
                                        print("Delete clicked");
                                      }
                                    },
                                    itemBuilder: (BuildContext context) => [
                                      PopupMenuItem(
                                        value: 'edit',
                                        child: Text("Edit Debt"),
                                      ),
                                      PopupMenuItem( // custom divider
                                        enabled: false, // not selectable
                                        height: 10,     // shrink height
                                        child: Container(
                                          margin: EdgeInsets.symmetric(horizontal: 2), // padding left & right
                                          height: 1,
                                          color: Colors.grey,
                                        ),
                                      ),
                                      PopupMenuItem(
                                        value: 'delete',
                                        child: Text("Delete Debt"),
                                      ),
                                    ],
                                  ),
                                ],
                              ),


                              const SizedBox(height: 16),
                              // Action Buttons based on status and role
                              _buildActionButtons(debt, isCreditor, isBorrower, debtProvider),
                            ],
                          ),
                        ),

                      // Debt Items
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Dubie Items:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          ElevatedButton.icon(
                              onPressed: () => _payAllForm(debt),
                              icon: Icon(Icons.payments),
                            label: Text("Pay All"),
                          )
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (debt.items == null || debt.items!.isEmpty)
                        const Text('No items in this dubie yet.', style: TextStyle(color: Colors.grey)),
                      if (debt.items != null)
                        ...debt.items!.map((item) {
                          final Color itemStatusColor = item.isPaid ? Colors.green : Colors.orange;
                          final String itemStatusText = item.isPaid ? 'Paid' : 'Pending';
                          final double remainingAmount = item.price - item.paidAmount;

                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 4.0),
                            child: ListTile(
                              title: Text(item.description),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Amount: ${currencyFormatter.format(item.price)}'),
                                  Text('Paid: ${currencyFormatter.format(item.paidAmount)}'),
                                  Text(
                                    '$itemStatusText ${item.isPaid ? '' : '(Remaining: ${currencyFormatter.format(remainingAmount)})'}',
                                    style: TextStyle(color: itemStatusColor, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                              trailing: !item.isPaid && isCreditor
                                  ? IconButton(
                                icon: const Icon(Icons.payment, color: Colors.blue),
                                onPressed: debtProvider.isActionInProgress
                                    ? null
                                    : () => _payDebtItemForm(item.id, item.paidAmount, item.price),
                              )
                                  : null,
                            ),
                          );
                        }).toList(),
                      const SizedBox(height: 16),

                      // Add New Item
                      if (isCreditor && (debt.status == 'new' || debt.status == 'accepted' || debt.status == 'amended_pending_reacceptance'))
                        ElevatedButton.icon(
                          onPressed: debtProvider.isActionInProgress ? null : _showAddItemDialog,
                          icon: const Icon(Icons.add_shopping_cart),
                          label: const Text('Add New Item'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blueAccent, // Use a distinct color
                            foregroundColor: Colors.white,
                          ),
                        ),
                      const SizedBox(height: 24),

                      // Comments Section
                      const Text('Comments:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      if (debtProvider.isLoadingComments && debtProvider.comments == null)
                        const Center(child: CircularProgressIndicator())
                      else if (debtProvider.commentsError != null)
                        Center(child: Text('Error loading comments: ${debtProvider.commentsError}'))
                      else if (debtProvider.comments!.isEmpty)
                          const Text('No comments yet.', style: TextStyle(color: Colors.grey)),
                      if (debtProvider.comments != null)
                        ...debtProvider.comments!.map((comment) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4.0),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                CircleAvatar(
                                  radius: 20,
                                  backgroundColor: Colors.blueGrey,
                                  child: Text(
                                    comment.commenterName?.substring(0, 1).toUpperCase() ?? '?',
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        comment.commenterName ?? 'Anonymous',
                                        style: const TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                      Text(comment.commentText),
                                      Text(
                                        DateFormat.yMMMd().add_jm().format(comment.date),
                                        style: const TextStyle(fontSize: 10, color: Colors.grey),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                    ],
                  ),
                ),
                // Comment Input Box
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _commentController,
                          decoration: InputDecoration(
                            hintText: 'Add a comment...',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20.0),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          ),
                          maxLines: null, // Allows multiline input
                          minLines: 1,
                        ),
                      ),
                      const SizedBox(width: 8),
                      debtProvider.isActionInProgress
                          ? const CircularProgressIndicator()
                          : IconButton(
                        icon: const Icon(Icons.send, color: Colors.green),
                        onPressed: _addComment,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildActionButtons(Debt debt, bool isCreditor, bool isBorrower, DebtProvider debtProvider) {
    if (debtProvider.isActionInProgress) {
      return const Center(child: CircularProgressIndicator());
    }

    List<Widget> buttons = [];

    // Actions for Borrower (User who owes)
    if (isBorrower) {
      if (debt.status == 'new' || debt.status == 'pending_acceptance' || debt.status == 'amended_pending_reacceptance') {
        buttons.add(ElevatedButton(
          onPressed: () async {
            try {
              await debtProvider.acceptDebt(debt.id);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Debt accepted!')),
                );
              }
            } on ApiException catch (e) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Failed to accept: ${e.message}')),
                );
              }
            }
          },
          style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
          child: const Text('Accept Dubie'),
        ));
      }
      if (debt.status == 'new' || debt.status == 'pending_acceptance' || debt.status == 'amended_pending_reacceptance') {
        buttons.add(ElevatedButton(
          onPressed: () async {
            try {
              await debtProvider.rejectDebt(debt.id);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Debt rejected!')),
                );
              }
            } on ApiException catch (e) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Failed to reject: ${e.message}')),
                );
              }
            }
          },
          style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white),
          child: const Text('Reject Dubie'),
        ));
      }
    }

    // Actions for Creditor (User who is owed) - Less direct actions here, mainly adding items.
    // Accept/Reject logic is primarily for the borrower.
    // Creditor can typically amend/add items which might trigger 'amended_pending_reacceptance'

    if (buttons.isEmpty) {
      return const SizedBox.shrink(); // No actions
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        alignment: WrapAlignment.center,
        children: buttons,
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'new':
      case 'pending_acceptance':
      case 'amended_pending_reacceptance':
        return Colors.orange;
      case 'accepted':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'completed':
        return Colors.blueGrey;
      default:
        return Colors.grey;
    }
  }
}