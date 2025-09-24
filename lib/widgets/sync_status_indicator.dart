import 'package:flutter/material.dart';

class SyncStatusIndicator extends StatelessWidget {
  final bool isSynced;

  const SyncStatusIndicator({super.key, required this.isSynced});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        color: isSynced ? Colors.green : Colors.red,
        shape: BoxShape.circle,
      ),
    );
  }
}