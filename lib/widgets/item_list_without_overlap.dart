import 'package:dubie_app/core/custom_colors.dart';
import 'package:flutter/material.dart';

// Helper to build item chip (corrected: removed internal margin)
Widget _buildItemChip(BuildContext context, {required String text}) {
  final colorScheme = Theme.of(context).colorScheme;
  return
    Container(
    height: 36,
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    // REMOVED: margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
    // Rely on Wrap's spacing for this
    decoration: BoxDecoration(
      color: colorScheme.homeOnCardButtonBackground,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(
        color: colorScheme.homeOnCardButtonBorder,
        width: 1.5,
      ),
      // boxShadow: [
      //   BoxShadow(
      //     color: Colors.black.withOpacity(0.1),
      //     blurRadius: 4,
      //     offset: const Offset(0, 2),
      //   ),
      // ],
    ),

      child: Text(
        text,
        style: TextStyle(
          fontSize: 13,
          color: colorScheme.textBoldColor,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
}

// Widget to display all chips with wrap-around behavior
class WrapAroundChipDisplay extends StatelessWidget {
  final List<String> items;

  const WrapAroundChipDisplay({
    super.key,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const SizedBox.shrink(); // Don't display anything if the list is empty
    }

    return Wrap(
      spacing: 8.0, // Horizontal space between chips
      runSpacing: 8.0, // Vertical space between rows of chips
      children: items.map((item) => _buildItemChip(context, text: item)).toList(),
    );
  }
}
