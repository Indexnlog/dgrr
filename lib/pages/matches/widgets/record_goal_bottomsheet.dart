import 'package:flutter/material.dart';

class RecordGoalBottomSheet extends StatefulWidget {
  final List<String> players;
  final Map<String, String> displayMap;
  final void Function(String playerId, String memo) onSave;

  const RecordGoalBottomSheet({
    super.key,
    required this.players,
    required this.displayMap,
    required this.onSave,
  });

  @override
  State<RecordGoalBottomSheet> createState() => _RecordGoalBottomSheetState();
}

class _RecordGoalBottomSheetState extends State<RecordGoalBottomSheet> {
  String? selectedPlayer;
  String memo = '';

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('⚽ 득점 기록 추가', style: Theme.of(context).textTheme.titleLarge),
          DropdownButton<String>(
            value: selectedPlayer,
            isExpanded: true,
            hint: const Text('선수 선택'),
            items: widget.players
                .map(
                  (id) => DropdownMenuItem(
                    value: id,
                    child: Text(widget.displayMap[id] ?? id),
                  ),
                )
                .toList(),
            onChanged: (val) => setState(() => selectedPlayer = val),
          ),
          TextField(
            decoration: const InputDecoration(labelText: '메모'),
            onChanged: (val) => memo = val,
          ),
          const SizedBox(height: 8),
          FilledButton(
            onPressed: selectedPlayer == null
                ? null
                : () {
                    widget.onSave(selectedPlayer!, memo);
                    Navigator.pop(context);
                  },
            child: const Text('저장'),
          ),
        ],
      ),
    );
  }
}
