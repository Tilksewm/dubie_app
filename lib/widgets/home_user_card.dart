import 'package:dubie_app/l10n/app_localizations.dart';
import 'package:dubie_app/providers/home_provider.dart';
import 'package:dubie_app/providers/language_provider.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // For number formatting
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:dubie_app/models/user.dart';
import 'package:dubie_app/screens/user_debts_detail_screen.dart';


import 'item_list_with_overlap.dart'; // We will create this next

class HomeUserCard extends StatelessWidget {
  final HomeUser homeUser;
  final bool isOwedByMe; // True if homeUser owes current user, false if current user owes homeUser
  const HomeUserCard({
    super.key,
    required this.homeUser,
    required this.isOwedByMe,
  });
  Future<void> inviteFriend() async {
    final message = Uri.encodeComponent(
        "Hey! I'm using Dubé to track debts. Download it here: https://dubeapp.com/download"
    );

    final smsUri = Uri.parse("sms:?body=$message");

    if (await canLaunchUrl(smsUri)) {
      await launchUrl(smsUri);
    } else {
      throw "Could not launch SMS app";
    }
  }


  @override
  Widget build(BuildContext context) {
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
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: InkWell(
        onTap: () {
           Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => UserDebtsDetailScreen(
                otherUserId: homeUser.userId,
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
                          homeUser.name ?? 'Unknown User',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          height: 40,
                           child: OverlappingChipStack(items: homeUser.recentItems,)
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
                      userStatus(homeUser.type),
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
  Widget userStatus( String userStatus) {
    if (userStatus == 'real') {
      return Text(
        'User',
        style: TextStyle(
          fontSize: 14,
          color: Colors.green,
        ),
      );
    } else {
      return ElevatedButton(
        onPressed: inviteFriend,
        child: Text(
          'Invite',
          style: TextStyle(
            fontSize: 14,
            color: Colors.green,
          ),
        ),
      );
    }
  }
}