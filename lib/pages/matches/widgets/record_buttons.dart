import 'package:flutter/material.dart';

class RecordButtons extends StatelessWidget {
  final VoidCallback? onAddGoal;
  final VoidCallback? onAddChange;

  const RecordButtons({super.key, this.onAddGoal, this.onAddChange});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        ElevatedButton.icon(
          icon: const Icon(Icons.sports_soccer),
          label: const Text('득점 기록'),
          onPressed: onAddGoal,
        ),
        const SizedBox(width: 12),
        ElevatedButton.icon(
          icon: const Icon(Icons.compare_arrows),
          label: const Text('교체 기록'),
          onPressed: onAddChange,
        ),
      ],
    );
  }
}
