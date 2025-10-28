import 'package:dubie_app/core/custom_colors.dart';
import 'package:dubie_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // For number formatting
import 'package:share_plus/share_plus.dart';
import 'package:dubie_app/models/user.dart';
import 'package:dubie_app/screens/user_debts_detail_screen.dart';


import '../models/home_user.dart';
import 'item_list_with_overlap.dart'; // We will create this next

class HomeUserCard extends StatelessWidget {
  final User mainUser;
  final HomeUser homeUser;
  final bool isOwedByMe; // True if homeUser owes current user, false if current user owes homeUser
  const HomeUserCard({
    super.key,
    required this.homeUser,
    required this.isOwedByMe,
    required this.mainUser,
  });
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
    final colorScheme = Theme.of(context).colorScheme;
    // Format numbers as currency
    final NumberFormat currencyFormatter = NumberFormat.currency(
      locale: 'en_US', // Or your desired locale for currency
      symbol: 'ETB ', // Ethiopian Birr, or '$' etc.
      decimalDigits: 2,
    );
    final loc = AppLocalizations.of(context)!;

    // Determine color based on whether the amount is owed by me or owes me
    Color amountColor = isOwedByMe ? Colors.green.shade700 : Colors.red.shade700;
    String amountPrefix = isOwedByMe ? '+' : '-';
    String totalAmount = '';
    if (homeUser.totalAmount == 0){
      totalAmount = loc.paid;
    }else{
      totalAmount = '$amountPrefix${currencyFormatter.format(homeUser.totalAmount.abs())}';
    }
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
      elevation: 0,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: colorScheme.homeOnCardButtonBorder, width: 1)),
      color: colorScheme.homeCardBackground,
      child: InkWell(
        onTap: () async {
           Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => UserDebtsDetailScreen(
                otherUserId: homeUser.userId,
                mainUser: mainUser,
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Left side: name + items
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          homeUser.name ?? loc.unknownUser,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          height: 40,
                           child: OverlappingChipStack(items: homeUser.recentItems, )
                        ),
                      ],
                    ),
                  ),

                  // Right side: amount + status
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        totalAmount,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: amountColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      userStatus(homeUser.type, context),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
  Widget userStatus( String userStatus, BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final loc = AppLocalizations.of(context)!;
    if (userStatus == 'real') {
      return Text(
        loc.user,
        style: TextStyle(
          fontSize: 14,
          color: colorScheme.textSubTitle,
        ),
      );
    } else {
      return ElevatedButton(
        style: ButtonStyle(
          shape: WidgetStateProperty.all<RoundedRectangleBorder>(
            RoundedRectangleBorder(
                side: BorderSide(color: colorScheme.homeOnCardButtonBorder, width: 1),
                borderRadius: BorderRadius.circular(10)),
          ),
          elevation: WidgetStateProperty.all<double>(0),
          backgroundColor: WidgetStateProperty.all<Color>(colorScheme.homeOnCardButtonBackground),
        ),
        onPressed: inviteFriend,
        child: Text(
          loc.invite,
          style: TextStyle(
            fontSize: 14,
            color: colorScheme.textSubTitle,
          ),
        ),
      );
    }
  }
}