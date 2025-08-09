import 'package:flutter/material.dart';

// Helper to build item chip (corrected: removed internal margin)
Widget _buildItemChip({required String text}) {
  return Expanded(child:
    Container(
    height: 36,
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    // REMOVED: margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
    // Rely on Wrap's spacing for this
    decoration: BoxDecoration(
      color: Colors.blue.shade50,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(
        color: Colors.blue.shade100,
        width: 1.5,
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.1),
          blurRadius: 4,
          offset: const Offset(0, 2),
        ),
      ],
    ),

      child: Text(
        text,
        style: TextStyle(
          fontSize: 13,
          color: Colors.blueAccent.shade700,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
  );
}

// Widget to display all chips with wrap-around behavior
class WrapAroundChipDisplay extends StatelessWidget {
  final List<String> items;

  const WrapAroundChipDisplay({
    Key? key,
    required this.items,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const SizedBox.shrink(); // Don't display anything if the list is empty
    }

    return Wrap(
      spacing: 8.0, // Horizontal space between chips
      runSpacing: 8.0, // Vertical space between rows of chips
      children: items.map((item) => _buildItemChip(text: item)).toList(),
    );
  }
}
