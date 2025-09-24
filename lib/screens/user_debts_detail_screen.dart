import 'package:dubie_app/main.dart';
import 'package:dubie_app/providers/home_provider.dart';
import 'package:dubie_app/providers/user_provider.dart';
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

import '../models/user.dart';
import '../widgets/item_list_without_overlap.dart';

class UserDebtsDetailScreen extends StatefulWidget {
  final User mainUser;
  final String otherUserId;

  const UserDebtsDetailScreen({
    super.key,
    required this.otherUserId,
    required this.mainUser,
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
  late bool shouldHomeRefresh;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshDebts();
    });
    shouldHomeRefresh = false;
  }

  Future<void> _refreshDebts() async {
    await Provider.of<DebtProvider>(context, listen: false).fetchDebtsWithUser(widget.otherUserId);
    await Provider.of<UserProvider>(context, listen: false).getUserById(widget.otherUserId);
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
  String getInitials(String fullName) {
    final parts = fullName.trim().split(" ");
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return "${parts[0][0].toUpperCase()}${parts[1][0].toUpperCase()}";
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
    final userProvider = Provider.of<UserProvider>(context);
    if(userProvider.currentUser == null || debtProvider.debtsWithUser == null){
      return Scaffold(
        body: Center(child: CircularProgressIndicator(),),
      );
    }
    double totalAmountWithUser = 0;
    double totalBorrowAmount = 0;
    double totalCreditAmount = 0;
    for (int i = 0; i < debtProvider.debtsWithUser!.length; i++){
      if (debtProvider.debtsWithUser?[i].debt.borrowerId == widget.otherUserId){
        totalCreditAmount += debtProvider.debtsWithUser?[i].outstandingAmount ?? 0;
      }else{
        totalBorrowAmount += debtProvider.debtsWithUser?[i].outstandingAmount ?? 0;
      }
    }
    totalAmountWithUser = totalCreditAmount - totalBorrowAmount;

    return WillPopScope(
        onWillPop: () async {
          if (shouldHomeRefresh) await homeProvider.fetchAllHomeData();
        // return true to allow pop, false to block it
        return true;
    },
    child: Scaffold(
      appBar: AppBar(
        title: GestureDetector(
          onTap: () {
            showDialog(
              context: context,
              builder: (ctx) {
                return Consumer<UserProvider>(
                    builder: (ctx, userProvider, child) {
                      return AlertDialog(
                        content:
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Center(
                              child: CircleAvatar(
                                radius: 40,
                                backgroundColor: Colors.teal.shade700,
                                child: Text(
                                  getInitials(userProvider.currentUser!.name),
                                  style: const TextStyle(
                                    fontSize: 28,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            Center(
                              child: Text(
                                userProvider.currentUser!.name,
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Center(
                              child: Text(
                                userProvider.currentUser!.email ?? "",
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                            ),

                            const SizedBox(height: 16),
                            if (userProvider.currentUser!.phone != null &&
                                userProvider.currentUser!.phone!
                                    .isNotEmpty) ...[
                              Row(
                                children: [
                                  const Icon(
                                      Icons.phone, color: Colors.blueAccent),
                                  const SizedBox(width: 10),
                                  Text(userProvider.currentUser!.phone!),
                                ],
                              ),
                              const SizedBox(height: 10),
                            ],
                            if (userProvider.currentUser!.username != null &&
                                userProvider.currentUser!.username!
                                    .isNotEmpty) ...[
                              Row(
                                children: [
                                  const Icon(Icons.person, color: Colors.teal),
                                  const SizedBox(width: 10),
                                  Text(userProvider.currentUser!.username!),
                                ],
                              ),
                            ],
                          ],
                        ),

                        actions: [
                          userProvider.currentUser!.userType != 'real' ?
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton(
                                onPressed: () {
                                  Navigator.of(ctx).pop(); // Close dialog
                                },
                                child: const Text('Close'),
                              ),
                              ElevatedButton(
                                onPressed: () async {
                                  await Navigator.of(context).push(
                                    MaterialPageRoute(builder: (ctx) =>
                                        UserInfoScreen(
                                            user: userProvider.currentUser!)),
                                  );
                                  // Refresh profile data in drawer after editing
                                  userProvider.getUserById(
                                      userProvider.currentUser!.id);
                                },
                                child: const Text('Edit'),
                              ),
                            ],
                          ) :
                          TextButton(
                            onPressed: () {
                              Navigator.of(ctx).pop(); // Close dialog
                            },
                            child: const Text('Close'),
                          ),
                        ],
                      );
                    }
                );
              });
            },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(userProvider.currentUser!.name ?? 'Debt Details', style: const TextStyle(fontSize: 18)),
              Text(
                'Total: ${currencyFormatter.format(totalAmountWithUser)}',
                style: const TextStyle(fontSize: 14, color: Colors.white70),
              ),
            ],
          ),
        ),

        actions: [
          Padding(padding: EdgeInsets.fromLTRB(0, 0, 30, 0),
            child: userStatus(userProvider.currentUser!.userType),
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
            child: LayoutBuilder(builder: (context, constraints){
              return ListView(
                children: [
                  ConstrainedBox (
                      constraints: BoxConstraints(minHeight: constraints.maxHeight),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('No debt threads found with ${userProvider.currentUser!.name ?? "this user"}.'),
                            const SizedBox(height: 20),
                            ElevatedButton.icon(
                              onPressed: () async {
                                final result = await Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) => CreateDebtScreen(
                                      initialBorrower: userProvider.currentUser!,
                                      initialCreditor: widget.mainUser,
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
                ],
              );
            }),
          )
          :
          RefreshIndicator(
            onRefresh: _refreshDebts,
            child: ListView.builder(
              itemCount: debtProvider.debtsWithUser!.length,
              itemBuilder: (context, index) {
                if (kDebugMode) {
                  print("Rendering index $index");
                  print(debtProvider.debtsWithUser!.map((d) => d.debt.id).toList());
                }
                final debtThread = debtProvider.debtsWithUser![index];
                final debt = debtThread.debt;
                // Determine direction from the perspective of the *current user*
                final bool isCreditorForThisDebtThread = debt.creditorId == debtProvider.currentUserId;
                Color amountColor = isCreditorForThisDebtThread ? Colors.green.shade700 : Colors.red.shade700;
                String amountPrefix = isCreditorForThisDebtThread ? '+' : '-';
                String debtAmount = '';
                if(debtThread.outstandingAmount == 0){
                  debtAmount = 'Paid';
                }else{
                  debtAmount = '$amountPrefix${currencyFormatter.format((debtThread.outstandingAmount ?? 0.0).abs())}';
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
                            otherUserName: userProvider.currentUser!.name,
                          ),
                        ),
                      );
                        debtProvider.fetchDebtsWithUser(userProvider.currentUser!.id);
                        context.read<HomeProvider>().fetchAllHomeData();
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
                          SizedBox.fromSize(child: WrapAroundChipDisplay(items: debtThread.items.map((e) => e.description).toList(),)
                          ),

                          // Display items related to this debt thread
                          if (debtThread.items != null && debtThread.items.isNotEmpty) ...[
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
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Created: ${DateFormat.yMMMd().format(DateTime.parse(debt.createdAt))}',
                                style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                              ),
                              if (debt.createdBy != null )
                                debt.borrowerId == debtProvider.currentUserId ?
                                  Text(
                                    'Created By: You',
                                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                                  ):
                                  Text(
                                      'Created By: ${userProvider.currentUser!.name}'
                                  ),
                            ],

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
                initialBorrower: userProvider.currentUser!,
                initialCreditor: widget.mainUser,
              ),
            ),
          );
          if (result == true) {
            _refreshDebts(); // Refresh if a new debt was created
          }
        },
        child: const Icon(Icons.add),
      ),
    ),
    );
  }
  Widget userStatus (String userStatus) {
    if (userStatus == 'real') {
      return SizedBox.shrink();
    } else {
      return ElevatedButton(
        onPressed: inviteFriend,
        child: Text(
          'Invite',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
      );
    }
  }
}
