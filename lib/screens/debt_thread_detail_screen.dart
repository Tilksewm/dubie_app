// import 'dart:ffi';
import 'dart:io';
import 'package:dubie_app/app_constants.dart';
import 'package:dubie_app/l10n/app_localizations.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'package:dubie_app/models/debt_item.dart';
// import 'package:dubie_app/screens/user_debts_detail_screen.dart';
import 'package:dubie_app/widgets/edit_debt_form.dart';
import 'package:dubie_app/widgets/new.dart';
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

  BannerAd? _bannerAd;
  bool _isBannerAdLoaded = false;
  bool shouldHomeRefresh = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<DebtProvider>(context, listen: false).fetchDebtDetails(widget.debtId);
    });
  }
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadBannerAd();
  }
  void _loadBannerAd() async {
    final width = MediaQuery.of(context).size.width.truncate();
    final AnchoredAdaptiveBannerAdSize? size =
        await AdSize.getCurrentOrientationAnchoredAdaptiveBannerAdSize(width);

    if (size == null) {
      debugPrint('Failed to get adaptive ad size');
      return;
    }
    _bannerAd = BannerAd(
      adUnitId: AppConstants.bannerAdUnitIdDetailThread,
      request: const AdRequest(),
      size: size,
      listener: BannerAdListener(
        onAdLoaded: (Ad ad) {
          print('$BannerAd loaded.');
          setState(() {
            _bannerAd = ad as BannerAd;
            _isBannerAdLoaded = true;
          });
        },
        onAdFailedToLoad: (Ad ad, LoadAdError error) {
          print('$BannerAd failedToLoad: $error');
          ad.dispose();
          setState(() {
            _isBannerAdLoaded = false;
          });
        },
        onAdOpened: (Ad ad) => print('$BannerAd onAdOpened.'),
        onAdClosed: (Ad ad) => print('$BannerAd onAdClosed.'),
        onAdImpression: (Ad ad) => print('$BannerAd onAdImpression.'),
      ),
    )..load();
  }

  void _updateDebt (BuildContext context, DebtThread debtThread){
    showDialog(
        context: context,
        builder: (_) => SizedBox(
          width: MediaQuery.of(context).size.width * 0.9,
          height: MediaQuery.of(context).size.height * 0.7,
          child: EditDebtForm(debtThread: debtThread),
        )
    );
  }
  Future<void> _deleteDebt(BuildContext context, DebtThread debtThread) async {
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
                
                if (mounted) {
                  Navigator.of(ctx).pop(); // Pop dialog
                  Navigator.of(context).pop(true);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(loc.debtDeletedSuccessfully)),
                  );
                }
              } catch (e) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  SnackBar(content: Text(loc.failedToDeleteDebt)),
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
  Future<void> _refreshDebtDetails() async {
    await Provider.of<DebtProvider>(context, listen: false).fetchDebtDetails(widget.debtId);
  }

  Future<void> _addComment() async {
    final loc = AppLocalizations.of(context)!;
    if (_commentController.text.isEmpty) return;
    try {
      await Provider.of<DebtProvider>(context, listen: false)
          .addComment(widget.debtId, _commentController.text);
      _commentController.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(loc.commentAddedSuccessfully)),
        );
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(loc.failedToAddComment)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(loc.somethingWentWrong)),
        );
      }
    }
  }

  Future<void> _addDebtItem() async {
    final loc = AppLocalizations.of(context)!;
    if (_itemDescriptionController.text.isEmpty || _itemPriceController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc.enterItemDescriptionAndPrice)),
      );
      return;
    }
    final double? price = double.tryParse(_itemPriceController.text);
    if (price == null || price <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc.enterValidPositivePrice)),
      );
      return;
    }

    try {
      final provider = Provider.of<DebtProvider>(context, listen: false);
      provider.addDebtItem(DebtItem(
        id: provider.generateId(),
        debtId: widget.debtId,
        description: _itemDescriptionController.text,
        amount: price,
        createdAt: DateTime.now().toIso8601String(),
        updatedAt: DateTime.now().toIso8601String(),
      ));
      _itemDescriptionController.clear();
      _itemPriceController.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(loc.itemAdded)),
        );
        shouldHomeRefresh = true;
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(loc.failedToAddItem)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(loc.somethingWentWrong)),
        );
      }
    }
  }

  Future<void> _payDebtItemForm(DebtItem debtItem) async {
    final loc = AppLocalizations.of(context)!;
    final TextEditingController amountController = TextEditingController(text: '${debtItem.amount - debtItem.paidAmount}');
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(loc.recordPayment),
        content: TextField(
          controller: amountController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: '${loc.amountPaidMax} ${currencyFormatter.format(debtItem.amount - debtItem.paidAmount)})',
            hintText: loc.enterAmountToPay,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(loc.cancel),
          ),
          ElevatedButton(
            onPressed: () async {
              final double? amount = double.tryParse(amountController.text);
              if (amount == null || amount <= 0 || (debtItem.paidAmount + amount) > debtItem.amount) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(loc.enterValidAmount)),
                  );
                }
                return;
              }
              debtItem.paidAmount += amount;
              _payDebtItem(debtItem);
              Navigator.pop(context); // Close dialog
              shouldHomeRefresh = true;
            },
            child: Text(loc.pay),
          ),
        ],
      ),
    );
  }
  Future <void> _payDebtItem(DebtItem debtItem) async{
    final loc = AppLocalizations.of(context)!;
    try {
      await Provider.of<DebtProvider>(context, listen: false).payDebtItem(debtItem);
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(loc.failedToRecordPayment)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(loc.somethingWentWrong)),
        );
      }
    }
  }
  Future<void> _payRandomDebt(DebtThread debt, double totalAmount) async{
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
              _payDebtItem(item);
              totalAmount -= itemOutstanding;
            }else{
              item.paidAmount += totalAmount;
              _payDebtItem(item);
              totalAmount = 0;
              break;
            }
          }else{ break;}
        }
        _refreshDebtDetails();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(loc.paymentRecordedSuccessfully)),
          );
          shouldHomeRefresh = true;
        }
      }

      on ApiException catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(loc.failedToRecordPayment)),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(loc.somethingWentWrong)),
          );
        }
      }
    }else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc.enterAmountExceededOutstanding)
        )
      );
    }

    print("total payment: $totalAmount");
  }
  Future<void> _payAllForm(DebtThread debt) async {
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
              _payRandomDebt(debt, double.parse(totalPaymentController.text));
              totalPaymentController.clear();
              Navigator.pop(context);
            },
            child: Text(loc.pay),
          ),
        ],
      ),
    );
  }

  Future<void> _showAddItemDialog() async {
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
              _addDebtItem();
              Navigator.pop(context); // Close dialog
            },
            child: Text(loc.add),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    _commentController.dispose();
    _itemDescriptionController.dispose();
    _itemPriceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return PopScope<bool>(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, bool? result) {
        if (didPop) {
          return; // Pop already occurred
        }
        // Manually pop with the correct value
        Navigator.of(context).pop(shouldHomeRefresh);
      },
      child: Scaffold(
      appBar: AppBar(
        title: Consumer<DebtProvider>(
          builder: (context, debtProvider, child) {
            final debtThread = debtProvider.currentDebt;
            final debt = debtThread?.debt;
            if (debtProvider.isLoadingDebt && debt == null) {
              return Text(loc.loadingDebt);
            }
            final String titleText = debtThread?.items.length.toString() ?? debt!.overallDescription ?? 'Debt Details';
            final double outstanding = debtThread?.outstandingAmount ?? 0.0;
            final double totalAmount = debtThread?.totalAmount ?? 0.0;
            final double totalPaid = debtThread?.totalPaid ?? 0.0;
            final Color amountColor = outstanding >= 0 ? Colors.green.shade700 : Colors.red.shade700;
            final String amountPrefix = outstanding >= 0 ? '+' : ''; // No '-' for positive numbers

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("$titleText ${loc.items}", style: const TextStyle(fontSize: 18)),
                Text(
                  '${loc.paidAmount} ${currencyFormatter.format(totalPaid.abs())} / $totalAmount',
                  style: TextStyle(fontSize: 14, color: Colors.black),
                ),
              ],
            );
          },
        ),
        actions: [
      Consumer<DebtProvider>(
        builder: (context, debtProvider, child) {
          if (debtProvider.isLoadingDebt && debtProvider.currentDebt == null) {
            return const Center(child: CircularProgressIndicator());
          }
          if (debtProvider.debtError != null) {
            return Center(child: Text('${loc.error} ${debtProvider.debtError}'));
          }
          if (debtProvider.currentDebt == null) {
            return Center(child: Text('${loc.debtNotFound}'));
          }
        final Color amountColor = debtProvider.currentDebt!.outstandingAmount! >= 0 ? Colors.green.shade700 : Colors.red.shade700;
        return
          Padding(
            padding: EdgeInsets.fromLTRB(0,0, 30, 0),
              child:
              Column(
                children: [
                  Text(
                    loc.outstanding,
                    style: TextStyle(fontSize: 14,),
                  ),
                  Text(
                    currencyFormatter.format(debtProvider.currentDebt?.outstandingAmount),
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
            return Center(child: Text('${loc.error} ${debtProvider.debtError}'));
          }
          if (debtProvider.currentDebt == null) {
            return Center(child: Text(loc.debtNotFound));
          }

          final debtThread = debtProvider.currentDebt!;
          final debt = debtThread.debt;
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
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '${loc.status}: ${debt.status}',
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
                                  if ((debt.createdBy != null && isBorrower) || (isCreditor && debt.createdBy == null) )
                                  PopupMenuButton<String>(
                                    onSelected: (value) {
                                      if (value == 'edit') {
                                        _updateDebt(context, debtThread);
                                      } else if (value == 'delete') {
                                        _deleteDebt(context, debtThread);
                                      }
                                    },
                                    itemBuilder: (BuildContext context) => [
                                      PopupMenuItem(
                                        value: 'edit',
                                        child: Text(loc.editDebt),
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
                                        child: Text(loc.deleteDebt),
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
                          Text(loc.dubieItems, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          if ((debt.createdBy != null && isBorrower) || (isCreditor && debt.createdBy == null) )
                          ElevatedButton.icon(
                              onPressed: () => _payAllForm(debtThread),
                              icon: Icon(Icons.payments),
                            label: Text(loc.payAll),
                          )
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (debtThread.items.isEmpty)
                        Text(loc.noItemsInThisDubie, style: TextStyle(color: Colors.grey)),
                      ...debtThread.items.map((item) {
                        final Color itemStatusColor = item.isPaid ? Colors.green : Colors.orange;
                        final String itemStatusText = item.isPaid ? loc.paid : loc.pending;
                        final double remainingAmount = item.amount - item.paidAmount;

                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 4.0),
                          child: ListTile(
                            title: Text(item.description),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('${loc.amount}: ${currencyFormatter.format(item.amount)}'),
                                Text('${loc.paidAmount}: ${currencyFormatter.format(item.paidAmount)}'),
                                Text(
                                  '$itemStatusText ${item.isPaid ? '' : '(${loc.remaining}: ${currencyFormatter.format(remainingAmount)})'}',
                                  style: TextStyle(color: itemStatusColor, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            trailing: item.isPaid ?
                                Text(loc.paid, style: TextStyle(color: Colors.green, fontSize: 16),):
                               ((debt.createdBy != null && isBorrower) || (isCreditor && debt.createdBy == null) )
                                ? IconButton(
                              icon: const Icon(Icons.payment, color: Colors.blue),
                              onPressed: debtProvider.isActionInProgress
                                  ? null
                                  : () => _payDebtItemForm(item),
                            )
                                : null,
                          ),
                        );
                      }).toList(),
                      const SizedBox(height: 16),

                      // Add New Item
                      if ((debt.createdBy != null && isBorrower) || (isCreditor && debt.createdBy == null) )
                        ElevatedButton.icon(
                          onPressed: debtProvider.isActionInProgress ? null : _showAddItemDialog,
                          icon: const Icon(Icons.add_shopping_cart),
                          label: Text(loc.addNewItem),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blueAccent, // Use a distinct color
                            foregroundColor: Colors.white,
                          ),
                        ),
                      const SizedBox(height: 24),

                      _bannerAd != null && _isBannerAdLoaded
                          ? SizedBox(
                        height: _bannerAd!.size.height.toDouble(),
                        width: _bannerAd!.size.width.toDouble(),
                        child: AdWidget(ad: _bannerAd!),
                      )
                          : const SizedBox.shrink(), // Placeholder height until ad loads

                      const SizedBox(height: 24),
                      // Comments Section
                      Text('${loc.comments}:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      if (debtProvider.isLoadingComments && debtProvider.comments == null)
                        const Center(child: CircularProgressIndicator())
                      else if (debtProvider.commentsError != null)
                        Center(child: Text('${loc.errorLoadingComments}: ${debtProvider.commentsError}'))
                      else if (debtProvider.comments!.isEmpty)
                          Text(loc.noCommentsYet, style: const TextStyle(color: Colors.grey)),
                      if (debtProvider.comments != null)
                        ...debtProvider.comments!.map((comment) {
                          return Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: ChatMessageWidget(
                              message: comment.comment,
                              currentUserId: debtProvider.currentUserId!,
                            )
                            // Row(
                            //   crossAxisAlignment: CrossAxisAlignment.start,
                            //   children: [
                            //     CircleAvatar(
                            //       radius: 20,
                            //       backgroundColor: Colors.blueGrey,
                            //       child: Text (
                            //         comment.commenterName.substring(0, 1).toUpperCase(),
                            //         style: const TextStyle(color: Colors.white),
                            //       ),
                            //     ),
                            //     const SizedBox(width: 8),
                            //     Expanded(
                            //       child: Column(
                            //         crossAxisAlignment: CrossAxisAlignment.start,
                            //         children: [
                            //           Text(
                            //             comment.commenterName ?? 'Anonymous',
                            //             style: const TextStyle(fontWeight: FontWeight.bold),
                            //           ),
                            //           Text(comment.comment.commentText),
                            //           Text(
                            //             DateFormat.yMMMd().add_jm().format(DateTime.parse(comment.comment.createdAt)),
                            //             style: const TextStyle(fontSize: 10, color: Colors.grey),
                            //           ),
                            //         ],
                            //       ),
                            //     ),
                            //   ],
                            // ),
                          );
                        }),
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
                            hintText: loc.addCommentHint,
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
    )
    );
  }

  Widget _buildActionButtons(Debt debt, bool isCreditor, bool isBorrower, DebtProvider debtProvider) {
    final loc = AppLocalizations.of(context)!;
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
              await debtProvider.acceptDebt(debt);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('${loc.debtAccepted}!')),
                );
              }
            } on ApiException catch (e) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(loc.faildToAcceptDebt)),
                );
              }
            }
          },
          style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
          child: Text(loc.acceptDubie),
        ));
      }
      if (debt.status == 'new' || debt.status == 'pending_acceptance' || debt.status == 'amended_pending_reacceptance') {
        buttons.add(ElevatedButton(
          onPressed: () async {
            try {
              await debtProvider.rejectDebt(debt);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('${loc.debtRejected}!')),
                );
              }
            } on ApiException catch (e) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(loc.failedToRejectDebt)),
                );
              }
            }
          },
          style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white),
          child: Text(loc.rejectDubie),
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