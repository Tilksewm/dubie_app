import 'dart:io';
import 'package:dubie_app/app_constants.dart';
import 'package:dubie_app/l10n/app_localizations.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

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

  BannerAd? _bannerAd;
  bool _isBannerAdLoaded = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshDebts();
    });
    shouldHomeRefresh = false;
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
      adUnitId: AppConstants.bannerAdUnitIdDetail,
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
   @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
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
    final loc = AppLocalizations.of(context)!;
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

    return PopScope<bool>(
      canPop: false, // prevents the default back action
      onPopInvokedWithResult: (bool didPop, bool? result) {
        if (didPop) {
          return; // Pop already occurred
        }
        if (shouldHomeRefresh) homeProvider.fetchAllHomeData();
        // Manually pop with the correct value
        Navigator.of(context).pop(shouldHomeRefresh);
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
                                child: Text(loc.close),
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
                                child: Text(loc.edit),
                              ),
                            ],
                          ) :
                          TextButton(
                            onPressed: () {
                              Navigator.of(ctx).pop(); // Close dialog
                            },
                            child: Text(loc.close),
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
              Text(userProvider.currentUser!.name, style: const TextStyle(fontSize: 18)),
              Text(
                '${loc.total}: ${currencyFormatter.format(totalAmountWithUser)}',
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
              child: Text('${loc.error}: ${debtProvider.debtsWithUserError}'),
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
                            Text(loc.noDebtThreadFoundWith (userProvider.currentUser!.name)),
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
                              label: Text(loc.startNewDubie),
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
                // if (kDebugMode) {
                //   print("Rendering index $index");
                //   print(debtProvider.debtsWithUser!.map((d) => d.debt.id).toList());
                // }
                final debtThread = debtProvider.debtsWithUser![index];
                final debt = debtThread.debt;
                // Determine direction from the perspective of the *current user*
                final bool isCreditorForThisDebtThread = debt.creditorId == debtProvider.currentUserId;
                Color amountColor = isCreditorForThisDebtThread ? Colors.green.shade700 : Colors.red.shade700;
                String amountPrefix = isCreditorForThisDebtThread ? '+' : '-';
                String debtAmount = '';
                if(debtThread.outstandingAmount == 0){
                  debtAmount = loc.paid;
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
                      if (result == true) {
                        _refreshDebts(); // Refresh if something changed in the debt thread
                        shouldHomeRefresh = true;
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
                                  debt.overallDescription ?? loc.debtThread,
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
                          if (debtThread.items.isNotEmpty) ...[
                            // Text(
                            //   'Items: ${debt.items!.map((e) => e.description).join(', ')}',
                            //   style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                            //   maxLines: 1,
                            //   overflow: TextOverflow.ellipsis,
                            // ),

                          ],
                          Text(
                            '${loc.status}: ${debt.status}', // Use original status field
                            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '${loc.createdAt}: ${DateFormat.yMMMd().format(DateTime.parse(debt.createdAt))}',
                                style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                              ),
                              if (debt.createdBy != null )
                                debt.borrowerId == debtProvider.currentUserId ?
                                  Text(
                                    loc.createdByYou,
                                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                                  ):
                                  Text(
                                      loc.createdBy(userProvider.currentUser!.name),
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
            shouldHomeRefresh = true;
          }
        },
        child: const Icon(Icons.add),
      ),
      bottomNavigationBar: _bannerAd != null && _isBannerAdLoaded
          ? SizedBox(
        height: _bannerAd!.size.height.toDouble(),
        width: _bannerAd!.size.width.toDouble(),
        child: AdWidget(ad: _bannerAd!),
      )
          : const SizedBox.shrink(), // Placeholder height until ad loads
    ),
    );
  }
  Widget userStatus (String userStatus) {
    final loc = AppLocalizations.of(context)!;
    if (userStatus == 'real') {
      return SizedBox.shrink();
    } else {
      return ElevatedButton(
        onPressed: inviteFriend,
        child: Text(
          loc.invite,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
      );
    }
  }
}
