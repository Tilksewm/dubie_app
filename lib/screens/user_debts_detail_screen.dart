import 'package:dubie_app/providers/home_provider.dart';
import 'package:dubie_app/screens/user_info_screen.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import 'package:dubie_app/providers/debt_provider.dart';
import 'package:dubie_app/models/debt.dart';
import 'package:dubie_app/screens/debt_thread_detail_screen.dart';
import 'package:dubie_app/screens/create_debt_screen.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../widgets/item_list_without_overlap.dart';

class UserDebtsDetailScreen extends StatefulWidget {
  final String otherUserId;
  final String? otherUserName;
  final String? userType; // Passed from HomeUserCard for AppBar display

  const UserDebtsDetailScreen({
    super.key,
    required this.otherUserId,
    this.otherUserName,
    this.userType,
  });

  @override
  State<UserDebtsDetailScreen> createState() => _UserDebtsDetailScreenState();
}

class _UserDebtsDetailScreenState extends State<UserDebtsDetailScreen> {
  final NumberFormat currencyFormatter = NumberFormat.currency(
    locale: 'en_US',
    symbol: 'ETB ',
    decimalDigits: 2,
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<DebtProvider>(context, listen: false).fetchDebtsWithUser(widget.otherUserId);
    });
  }

  Future<void> _refreshDebts() async {
    await Provider.of<DebtProvider>(context, listen: false).fetchDebtsWithUser(widget.otherUserId);
  }

  void inviteFriend() {
    const inviteLink = "https://dubeapp.com/download"; // placeholder for now
    final message = "Hey! I'm using Dubé to track debts. "
        "Download it here: $inviteLink";

    SharePlus.instance.share(
      ShareParams(
        text: message,
        subject: "Join me on Dubé",
      )
    );
  }


  // Future<void> inviteFriend() async {
  //   final message = Uri.encodeComponent(
  //       "Hey! I'm using Dubé to track debts. Download it here: https://dubeapp.com/download"
  //   );
  //
  //   final smsUri = Uri.parse("sms:?body=$message");
  //
  //   if (await canLaunchUrl(smsUri)) {
  //     await launchUrl(smsUri);
  //   } else {
  //     throw "Could not launch SMS app";
  //   }
  // }


  @override
  Widget build(BuildContext context) {
    final debtProvider = Provider.of<DebtProvider>(context);
    double totalAmountWithUser = 0;
    double totalBorrowAmount = 0;
    double totalCreditAmount = 0;
    for (int i = 0; i < debtProvider.debtsWithUser!.length; i++){
      if (debtProvider.debtsWithUser?[i].borrowerId == widget.otherUserId){
        totalCreditAmount += debtProvider.debtsWithUser?[i].outstandingAmount ?? 0;
      }else{
        totalBorrowAmount += debtProvider.debtsWithUser?[i].outstandingAmount ?? 0;
      }
    }
    totalAmountWithUser = totalCreditAmount - totalBorrowAmount;
    return Scaffold(
      appBar: AppBar(
        title: GestureDetector(
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (context) =>
                UserInfoScreen(userId:widget.otherUserId, userName:widget.otherUserName!, userType: widget.userType!)
            )
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.otherUserName ?? 'Debt Details', style: const TextStyle(fontSize: 18)),
              Text(
                'Total: ${currencyFormatter.format(totalAmountWithUser)}',
                style: const TextStyle(fontSize: 14, color: Colors.white70),
              ),
            ],
          ),
        ),

        actions: [
          Padding(padding: EdgeInsets.fromLTRB(0, 0, 30, 0),
            child: userStatus('${widget.userType}'),
          )
        ],
      ),
      body:
          // for testing purpose
          // kDebugMode? {
          //   print(debtProvider.debtsWithUser!.map((d) => d.id).toList());
          // }

          debtProvider.isLoadingDebtsWithUser?
            const Center(child: CircularProgressIndicator())
              :
          debtProvider.debtsWithUserError != null?
            RefreshIndicator(
              onRefresh: _refreshDebts,
              child: Text('Error: ${debtProvider.debtsWithUserError}'),
            )
          :
          debtProvider.debtsWithUser == null || debtProvider.debtsWithUser!.isEmpty?
          RefreshIndicator(
              onRefresh: _refreshDebts,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('No debt threads found with ${widget.otherUserName ?? "this user"}.'),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: () async {
                        final result = await Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => CreateDebtScreen(
                              initialBorrowerId: widget.otherUserId,
                              initialBorrowerName: widget.otherUserName,
                            ),
                          ),
                        );
                        if (result == true) {
                          _refreshDebts(); // Refresh if a new debt was created
                        }
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('Start New Dubie'),
                    ),
                  ],
                ),
              )
          )
          :
          RefreshIndicator(
            onRefresh: _refreshDebts,
            child: ListView.builder(
              itemCount: debtProvider.debtsWithUser!.length,
              itemBuilder: (context, index) {
                if (kDebugMode) {
                  print("Rendering index $index");
                  print(debtProvider.debtsWithUser!.map((d) => d.id).toList());
                }
                final debt = debtProvider.debtsWithUser![index];
                // Determine direction from the perspective of the *current user*
                final bool isCreditorForThisDebtThread = debt.creditorId == debtProvider.currentUserId;
                Color amountColor = isCreditorForThisDebtThread ? Colors.green.shade700 : Colors.red.shade700;
                String amountPrefix = isCreditorForThisDebtThread ? '+' : '-';
                String debtAmount = '';
                if(debt.outstandingAmount == 0){
                  debtAmount = 'Paid';
                }else{
                  debtAmount = '$amountPrefix${currencyFormatter.format((debt.outstandingAmount ?? 0.0).abs())}';
                }

                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  elevation: 2,
                  child: InkWell(
                    onTap: () async {
                      // Navigate to Debt Thread Detail Screen for this specific debt_id
                      final result = await Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => DebtThreadDetailScreen(
                            debtId: debt.id,
                            otherUserName: widget.otherUserName,
                          ),
                        ),
                      );
                      if (result == true) {
                        _refreshDebts(); // Refresh if actions were performed on the debt thread
                      }
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  debt.overallDescription ?? 'Debt Thread',
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Text(
                                debtAmount,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: amountColor,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          SizedBox.fromSize(child: WrapAroundChipDisplay(items: debt.items!.map((e) => e.description).toList(),)
                          ),

                          // Display items related to this debt thread
                          if (debt.items != null && debt.items!.isNotEmpty) ...[
                            // Text(
                            //   'Items: ${debt.items!.map((e) => e.description).join(', ')}',
                            //   style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                            //   maxLines: 1,
                            //   overflow: TextOverflow.ellipsis,
                            // ),

                          ],
                          Text(
                            'Status: ${debt.status}', // Use original status field
                            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                          ),
                          Text(
                            'Created: ${DateFormat.yMMMd().format(debt.createdAt)}',
                            style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                          ),
                          // No last_comment field in original Debt model, so remove if present
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => CreateDebtScreen(
                initialBorrowerId: widget.otherUserId,
                initialBorrowerName: widget.otherUserName,
              ),
            ),
          );
          if (result == true) {
            _refreshDebts(); // Refresh if a new debt was created
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }
  Widget userStatus (String userStatus) {
    if (userStatus == 'User') {
      return Text(
        userStatus,
        style: TextStyle(
          fontSize: 14,
          color: Colors.grey[600],
        ),
      );
    } else {
      return ElevatedButton(
        onPressed: inviteFriend,
        child: Text(
          userStatus,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
      );
    }
  }
}
