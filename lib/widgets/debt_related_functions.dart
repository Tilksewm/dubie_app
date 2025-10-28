import 'package:dubie_app/core/custom_colors.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../models/debt_item.dart';
import '../providers/debt_provider.dart';
import '../services/api_service.dart';
import 'edit_debt_form.dart';

class DebtRelatedFunctions {

  static final TextEditingController _itemDescriptionController = TextEditingController();
  static final TextEditingController _itemPriceController = TextEditingController();

  static final NumberFormat currencyFormatter = NumberFormat.currency(
    locale: 'en_US',
    symbol: 'ETB ',
    decimalDigits: 2,
  );
  static Future<void> showAddItemDialog(BuildContext context, String debtId, {required Future<void> Function() onUpdate}) async {
    final loc = AppLocalizations.of(context)!;
    _itemDescriptionController.clear();
    _itemPriceController.clear();
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(loc.addNewDubieItem),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _itemDescriptionController,
              decoration: InputDecoration(labelText: loc.description),
            ),
            TextField(
              controller: _itemPriceController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: loc.amount),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(loc.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              _addDebtItem(context, debtId, onUpdate: onUpdate);
              Navigator.pop(context); // Close dialog
            },
            child: Text(loc.add),
          ),
        ],
      ),
    );
  }
  static Future<void> _addDebtItem(BuildContext context, String debtId, {required Future<void> Function() onUpdate}) async {
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

    try {
      final provider = Provider.of<DebtProvider>(context, listen: false);
      provider.addDebtItem(DebtItem(
        id: provider.generateId(),
        debtId: debtId,
        description: _itemDescriptionController.text,
        amount: price,
        createdAt: DateTime.now().toIso8601String(),
        updatedAt: DateTime.now().toIso8601String(),
      ));
      _itemDescriptionController.clear();
      _itemPriceController.clear();
      await onUpdate();
      //if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(loc.itemAdded)),
        );
       // shouldHomeRefresh = true;
      //}
    } on ApiException catch (e) {
      //if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(loc.failedToAddItem),
            backgroundColor: Theme.of(context).colorScheme.withdrawColor,),
        );
      //}
    } catch (e) {
      //if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(loc.somethingWentWrong),
            backgroundColor: Theme.of(context).colorScheme.withdrawColor,),
        );
      //}
    }
  }
  static void updateDebt (BuildContext context, DebtThread debtThread, {required Future<void> Function() onUpdate}){
    showDialog(
        context: context,
        builder: (_) => SizedBox(
          width: MediaQuery.of(context).size.width * 0.9,
          height: MediaQuery.of(context).size.height * 0.7,
          child: EditDebtForm(debtThread: debtThread, onUpdate: onUpdate),
        )
    );
  }
  static Future<void> deleteDebt(BuildContext context, DebtThread debtThread, String callFrom, {required Future<void> Function() onUpdate}) async {
    final loc = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(loc.deleteDebt),
        content: Text(loc.deleteDebtConfirmation),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(loc.cancel),
          ),
          ElevatedButton(
            onPressed: () async {
              // Implement delete debt logic here
              // This usually involves an API call to your backend
              // Then log out the user and navigate to login screen
              // For now, just log out as a placeholder
              try {
                await Provider.of<DebtProvider>(context, listen: false).deleteDebt(debtThread);
                await onUpdate();

                  Navigator.of(ctx).pop(); // Pop dialog
                  if (callFrom == 'debtThread') {
                    Navigator.of(context).pop(true);
                  }
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(loc.debtDeletedSuccessfully),),
                  );
              } catch (e) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  SnackBar(content: Text(loc.failedToDeleteDebt),
                    backgroundColor: Theme.of(context).colorScheme.withdrawColor,),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text(loc.delete, style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
  static Future <void> _payDebtItem(BuildContext context, DebtItem debtItem) async{
    final loc = AppLocalizations.of(context)!;
    try {
      await Provider.of<DebtProvider>(context, listen: false).payDebtItem(debtItem);
    } on ApiException catch (e) {
      // if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(loc.failedToRecordPayment),
            backgroundColor: Theme.of(context).colorScheme.withdrawColor,),
        );

    } catch (e) {
      //if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(loc.somethingWentWrong),
            backgroundColor: Theme.of(context).colorScheme.withdrawColor,),
        );
      //}
    }
  }
  static Future<void> _payRandomDebt(BuildContext context, DebtThread debt, double totalAmount, {required Future<void> Function() onUpdate}) async{
    final loc = AppLocalizations.of(context)!;
    final outstandingAmount = debt.items.map((item) => item.amount - item.paidAmount).reduce((a, b) => a + b);
    if (totalAmount <= outstandingAmount){
      List<DebtItem> items = debt.items;
      try{
        for (var item in items){
          if (totalAmount > 0){
            var itemOutstanding = item.amount - item.paidAmount;
            if (totalAmount >= itemOutstanding){
              item.paidAmount += itemOutstanding;
              _payDebtItem(context, item);
              totalAmount -= itemOutstanding;
            }else{
              item.paidAmount += totalAmount;
              _payDebtItem(context, item);
              totalAmount = 0;
              break;
            }
          }else{ break;}
        }
        //_refreshDebtDetails();
        //if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(loc.paymentRecordedSuccessfully)),
          );
          //shouldHomeRefresh = true;
        //}
      }

      on ApiException catch (e) {
        //if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(loc.failedToRecordPayment),
              backgroundColor: Theme.of(context).colorScheme.withdrawColor,),
          );
        //}
      } catch (e) {
        //if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(loc.somethingWentWrong),
              backgroundColor: Theme.of(context).colorScheme.withdrawColor,),
          );
        //}
      }finally{
        await onUpdate();
      }
    }else {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(loc.enterAmountExceededOutstanding),
            backgroundColor: Theme.of(context).colorScheme.withdrawColor,
          )
      );
    }

    print("total payment: $totalAmount");
  }
  static Future<void> payAllForm(BuildContext context, DebtThread debt, {required Future<void> Function() onUpdate}) async {
    final loc = AppLocalizations.of(context)!;
    final outstandingAmount = debt.items.map((item) => item.amount - item.paidAmount).reduce((a,b) => (a+b));
    final TextEditingController totalPaymentController = TextEditingController(text: "$outstandingAmount");

    await showDialog(context: context, builder: (context) =>
        AlertDialog(
          title: Text(loc.enterTotalAmount),
          content: TextField(
              controller: totalPaymentController,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                labelText: "${loc.paidAmount} ${currencyFormatter.format(outstandingAmount)})",
                hintText: loc.enterTotalAmount,
              )
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(loc.cancel),
            ),
            ElevatedButton(
              onPressed: () {
                _payRandomDebt(context, debt, double.parse(totalPaymentController.text), onUpdate: onUpdate);
                totalPaymentController.clear();
                Navigator.pop(context);
              },
              child: Text(loc.pay),
            ),
          ],
        ),
    );
  }
}