import 'package:flutter/material.dart';
import 'dart:math';
// Helper to build item chip
Widget _buildItemChip({required String text, bool isOverflowChip = false}) {
  return Container(
    height: 36, // Slightly increased height for better visual
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    decoration: BoxDecoration(
      color: isOverflowChip ? Colors.blueAccent.shade700 : Colors.blue.shade50,
      borderRadius: BorderRadius.circular(18), // More rounded corners
      border: Border.all(
        color: isOverflowChip ? Colors.blueAccent.shade700 : Colors.blue.shade100,
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
    child: Center(
      child: Text(
        text,
        style: TextStyle(
          fontSize: 13,
          color: isOverflowChip ? Colors.white : Colors.blueAccent.shade700,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
  );
}

// Truncate string to a reasonable length for chips
String _truncate(String input, {int maxLength = 11}) {
  if (input.length <= maxLength) return input;
  return '${input.substring(0, maxLength)}...';
}

// Helper to estimate the width of a chip based on its text
// This is a more robust way to estimate text width in Flutter.
double _estimateChipWidth(String text, TextStyle style) {
  final TextPainter textPainter = TextPainter(
    text: TextSpan(text: text, style: style),
    textDirection: TextDirection.ltr, // Required
  )..layout();
  // Add horizontal padding (12 * 2) and border (approx 1.5 * 2)
  return textPainter.width + (12 * 2) + (1.5 * 2);
}

// Widget to display a stack of overlapping chips
class OverlappingChipStack extends StatelessWidget {
  final List<String> items;
  final int maxVisibleItems; // How many chips to show before the overflow

  const OverlappingChipStack({
    super.key,
    required this.items,
    this.maxVisibleItems = 3, // Default to 3 visible chips + overflow
  });

  @override
  Widget build(BuildContext context) {
    List<Widget> chips = [];
    int actualVisibleCount = items.length.clamp(0, maxVisibleItems);
    double overlapOffset = 20.0; // How much each chip overlaps the previous one

    // Define the style for the chips for width estimation
    const chipTextStyle = TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w600,
    );

    // Calculate the estimated width of the widest potentially visible chip
    // We'll consider the truncated text width for visible chips
    double maxChipWidth = 0;
    if (items.isNotEmpty) {
      // Estimate width for the longest possible truncated chip text
      maxChipWidth = _estimateChipWidth(_truncate(items[0], maxLength: 10), chipTextStyle);
      // Also consider the overflow chip width
      final overflowText = '+${items.length - maxVisibleItems}';
      maxChipWidth = max(maxChipWidth, _estimateChipWidth(overflowText, chipTextStyle));
    } else {
      // Default width for an empty state, or a small placeholder
      maxChipWidth = _estimateChipWidth('Placeholder', chipTextStyle); // Or a fixed small value
    }


    // Add visible chips
    for (int i = 0; i < actualVisibleCount; i++) {
      chips.add(
        Positioned(
          left: i * overlapOffset,
          child: _buildItemChip(text: _truncate(items[i])),
        ),
      );
    }

    // Add overflow chip if necessary
    if (items.length > maxVisibleItems) {
      chips.add(
        Positioned(
          left: actualVisibleCount * overlapOffset,
          child: _buildItemChip(
            text: '+${items.length - maxVisibleItems}',
            isOverflowChip: true,
          ),
        ),
      );
    }

    // Calculate total width needed for the stack
    // (number of visible chips + 1 for overflow if present) * overlap + estimated last chip width
    double totalWidth;
    if (items.isEmpty) {
      totalWidth = 0; // No chips, no width
    } else if (items.length <= maxVisibleItems) {
      // Only visible chips, no overflow
      totalWidth = (actualVisibleCount - 1) * overlapOffset + maxChipWidth;
    } else {
      // Visible chips + overflow chip
      totalWidth = actualVisibleCount * overlapOffset + maxChipWidth;
    }

    return SizedBox(
      width: totalWidth > 0 ? totalWidth + 10 : 0, // Add some padding, ensure non-negative width
      height: 36, // Match chip height
      child: Stack(
        clipBehavior: Clip.none, // Allows children to draw outside bounds
        children: chips.reversed.toList(), // Reverse to show first item on top
      ),
    );
  }
}
