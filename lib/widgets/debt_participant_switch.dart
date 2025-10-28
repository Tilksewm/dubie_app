import 'package:dubie_app/core/custom_colors.dart';
import 'package:dubie_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

import '../models/user.dart';

class DebtParticipantSwitch extends StatefulWidget {
  final User initialGiver;
  final User initialBorrower;
  final void Function({required String creditorId, required String borrowerId}) onSwitch;

  const DebtParticipantSwitch({
    super.key,
    required this.initialGiver,
    required this.initialBorrower,
    required this.onSwitch,
    // required this.availableUsers,
  });

  @override
  State<DebtParticipantSwitch> createState() => _DebtParticipantSwitchState();
}

class _DebtParticipantSwitchState extends State<DebtParticipantSwitch> {
  late User _giver;
  late User _borrower;

  @override
  void initState() {
    super.initState();
    _giver = widget.initialGiver;
    _borrower = widget.initialBorrower;
  }

  @override
  void didUpdateWidget(covariant DebtParticipantSwitch oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialGiver != oldWidget.initialGiver) {
      _giver = widget.initialGiver;
    }
    if (widget.initialBorrower != oldWidget.initialBorrower) {
      _borrower = widget.initialBorrower;
    }
  }

  void _handleSwitch() {
    final temp = _giver;
    setState(() {
      _giver = _borrower;
      _borrower = temp;
    });
    widget.onSwitch(creditorId: _giver.id, borrowerId: _borrower.id);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final loc = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 12.0),
      decoration: BoxDecoration(
        border: Border.all(
          color: colorScheme.homeOnCardButtonBorder,
          width: 1
        ),
        color: colorScheme.homeCardBackground,
        borderRadius: BorderRadius.circular(8.0),
      ),

      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Expanded(
            child: _buildParticipantDisplay(
              user: _giver,
              label: loc.from,
              alignment: CrossAxisAlignment.start,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: IconButton(
              icon: const Icon(Icons.swap_horiz, size: 30.0),
              onPressed: _handleSwitch,
              tooltip: loc.switchGiverAndBorrower,
            ),
          ),
          Expanded(
            child: _buildParticipantDisplay(
              user: _borrower,
              label: loc.to,
              alignment: CrossAxisAlignment.end,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildParticipantDisplay({
    required User user,
    required String label,
    //required VoidCallback onTap,
    required CrossAxisAlignment alignment,
  }) {
    return InkWell(
      //onTap: onTap,
      borderRadius: BorderRadius.circular(4.0),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
        child: Column(
          crossAxisAlignment: alignment,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label.toUpperCase(),
              style: TextStyle(
                fontSize: 12.0,
                color: Colors.grey[700],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4.0),
            Text(
              user.name,
              style: const TextStyle(
                fontSize: 16.0,
                fontWeight: FontWeight.bold,
              ),
              textAlign: alignment == CrossAxisAlignment.start
                  ? TextAlign.left
                  : TextAlign.right,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

// import 'package:flutter/material.dart';
//
// // Assuming you have a User model, replace with your actual model
// class User {  final String id;
// final String name;
// // Add other relevant user properties
//
// User({required this.id, required this.name});
// }
//
// class DebtParticipantSwitch extends StatefulWidget {
//   final User initialGiver;
//   final User initialBorrower;
//   final VoidCallback onSwitch;
//   // final ValueChanged<User> onGiverChanged;
//   // final ValueChanged<User> onBorrowerChanged;
//   final List<User>
//   availableUsers; // List of users to choose from for giver/borrower
//
//   const DebtParticipantSwitch({
//     Key? key,
//     required this.initialGiver,
//     required this.initialBorrower,
//     required this.onSwitch,
//     // required this.onGiverChanged,
//     // required this.onBorrowerChanged,
//     required this.availableUsers,
//   }) : super(key: key);
//
//   @override
//   State<DebtParticipantSwitch> createState() => _DebtParticipantSwitchState();
// }
//
// class _DebtParticipantSwitchState extends State<DebtParticipantSwitch> {
//   late User _giver;
//   late User _borrower;
//
//   @override
//   void initState() {
//     super.initState();
//     _giver = widget.initialGiver;
//     _borrower = widget.initialBorrower;
//   }
//
//   @override
//   void didUpdateWidget(covariant DebtParticipantSwitch oldWidget) {
//     super.didUpdateWidget(oldWidget);
//     if (widget.initialGiver != oldWidget.initialGiver) {
//       _giver = widget.initialGiver;
//     }
//     if (widget.initialBorrower != oldWidget.initialBorrower) {
//       _borrower = widget.initialBorrower;
//     }
//   }
//
//   void _handleSwitch() {
//     final temp = _giver;
//     setState(() {
//       _giver = _borrower;
//       _borrower = temp;
//     });
//     // widget.onGiverChanged(_giver);
//     // widget.onBorrowerChanged(_borrower);
//     widget.onSwitch();
//   }
//
//   // Future<void> _selectUser(bool isGiver) async {
//   //   final selectedUser = await showModalBottomSheet<User>(
//   //     context: context,
//   //     builder: (BuildContext context) {
//   //       return ListView.builder(
//   //         shrinkWrap: true,
//   //         itemCount: widget.availableUsers.length,
//   //         itemBuilder: (context, index) {
//   //           final user = widget.availableUsers[index];
//   //           // Prevent selecting the same user for both roles if needed,
//   //           // or the current user for the other role.
//   //           bool isDisabled = (isGiver && user.id == _borrower.id) ||
//   //               (!isGiver && user.id == _giver.id);
//   //
//   //           return ListTile(
//   //             title: Text(user.name),
//   //             enabled: !isDisabled,
//   //             onTap: isDisabled ? null : () => Navigator.pop(context, user),
//   //           );
//   //         },
//   //       );
//   //     },
//   //   );
//   //
//   //   if (selectedUser != null) {
//   //     setState(() {
//   //       if (isGiver) {
//   //         // Check if the new giver is the current borrower
//   //         if (selectedUser.id == _borrower.id) {
//   //           // If so, swap them
//   //           _borrower = _giver; // Old giver becomes the new borrower
//   //           //widget.onBorrowerChanged(_borrower);
//   //         }
//   //         _giver = selectedUser;
//   //         //widget.onGiverChanged(_giver);
//   //       } else {
//   //         // Check if the new borrower is the current giver
//   //         if (selectedUser.id == _giver.id) {
//   //           // If so, swap them
//   //           _giver = _borrower; // Old borrower becomes the new giver
//   //           //widget.onGiverChanged(_giver);
//   //         }
//   //         _borrower = selectedUser;
//   //         //widget.onBorrowerChanged(_borrower);
//   //       }
//   //     });
//   //   }
//   // }
//
//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 12.0),
//       decoration: BoxDecoration(
//         color: Colors.grey[200],
//         borderRadius: BorderRadius.circular(8.0),
//       ),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//         children: <Widget>[
//           Expanded(
//             child: _buildParticipantDisplay(
//               user: _giver,
//               label: 'From',
//               //onTap: () => _selectUser(true),
//               alignment: CrossAxisAlignment.start,
//             ),
//           ),
//           Padding(
//             padding: const EdgeInsets.symmetric(horizontal: 8.0),
//             child: IconButton(
//               icon: const Icon(Icons.swap_horiz, size: 30.0),
//               onPressed: _handleSwitch,
//               tooltip: 'Switch Giver and Borrower',
//             ),
//           ),
//           Expanded(
//             child: _buildParticipantDisplay(
//               user: _borrower,
//               label: 'To',
//               //onTap: () => _selectUser(false),
//               alignment: CrossAxisAlignment.end,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildParticipantDisplay({
//     required User user,
//     required String label,
//     //required VoidCallback onTap,
//     required CrossAxisAlignment alignment,
//   }) {
//     return InkWell(
//       //onTap: onTap,
//       borderRadius: BorderRadius.circular(4.0),
//       child: Padding(
//         padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
//         child: Column(
//           crossAxisAlignment: alignment,
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             Text(
//               label.toUpperCase(),
//               style: TextStyle(
//                 fontSize: 12.0,
//                 color: Colors.grey[700],
//                 fontWeight: FontWeight.w500,
//               ),
//             ),
//             const SizedBox(height: 4.0),
//             Text(
//               user.name,
//               style: const TextStyle(
//                 fontSize: 16.0,
//                 fontWeight: FontWeight.bold,
//               ),
//               textAlign: alignment == CrossAxisAlignment.start
//                   ? TextAlign.left
//                   : TextAlign.right,
//               overflow: TextOverflow.ellipsis,
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
//
// // --- Example Usage ---
// class DebtSwitchExample extends StatefulWidget {
//   const DebtSwitchExample({super.key});
//
//   @override
//   State<DebtSwitchExample> createState() => _DebtSwitchExampleState();
// }
//
// class _DebtSwitchExampleState extends State<DebtSwitchExample> {
//   // Sample Users
//   final List<User> allUsers = [
//     User(id: '1', name: 'Alice Wonderland'),
//     User(id: '2', name: 'Bob The Builder'),
//     User(id: '3', name: 'Charlie Chaplin'),
//     User(id: '4', name: 'Diana Prince'),
//   ];
//
//   late User currentGiver;
//   late User currentBorrower;
//
//   @override
//   void initState() {
//     super.initState();
//     // Ensure initial giver and borrower are different if possible
//     currentGiver = allUsers[0];
//     currentBorrower = allUsers[1];
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Padding(
//       padding: const EdgeInsets.all(16.0),
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           DebtParticipantSwitch(
//             initialGiver: currentGiver,
//             initialBorrower: currentBorrower,
//             availableUsers: allUsers,
//             onSwitch: () {
//               setState(() {
//                 // The widget itself handles the state swap,
//                 // but we might want to update our parent state here too.
//                 final temp = currentGiver;
//                 currentGiver = currentBorrower;
//                 currentBorrower = temp;
//               });
//               print('Switched! New Giver: ${currentGiver.name}, New Borrower: ${currentBorrower.name}');
//             },
//             // onGiverChanged: (newGiver) {
//             //   setState(() {
//             //     currentGiver = newGiver;
//             //   });
//             //   print('Giver changed to: ${newGiver.name}');
//             // },
//             // onBorrowerChanged: (newBorrower) {
//             //   setState(() {
//             //     currentBorrower = newBorrower;
//             //   });
//             //   print('Borrower changed to: ${newBorrower.name}');
//             // },
//           ),
//           const SizedBox(height: 20),
//           Text('Current Giver: ${currentGiver.name}'),
//           Text('Current Borrower: ${currentBorrower.name}'),
//         ],
//       ),
//     );
//   }
// }

