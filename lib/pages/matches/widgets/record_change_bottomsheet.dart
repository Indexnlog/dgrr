import 'package:flutter/material.dart';

class RecordChangeBottomSheet extends StatefulWidget {
  final List<String> players;
  final Map<String, String> displayMap;
  final void Function(String outPlayerId, String inPlayerId, String memo)
  onSave;

  const RecordChangeBottomSheet({
    super.key,
    required this.players,
    required this.displayMap,
    required this.onSave,
  });

  @override
  State<RecordChangeBottomSheet> createState() =>
      _RecordChangeBottomSheetState();
}

class _RecordChangeBottomSheetState extends State<RecordChangeBottomSheet> {
  String? outPlayer;
  String? inPlayer;
  String memo = '';

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('🔄 교체 기록 추가', style: Theme.of(context).textTheme.titleLarge),
          DropdownButton<String>(
            value: outPlayer,
            isExpanded: true,
            hint: const Text('OUT 선수 선택'),
            items: widget.players
                .map(
                  (id) => DropdownMenuItem(
                    value: id,
                    child: Text(widget.displayMap[id] ?? id),
                  ),
                )
                .toList(),
            onChanged: (val) => setState(() => outPlayer = val),
          ),
          DropdownButton<String>(
            value: inPlayer,
            isExpanded: true,
            hint: const Text('IN 선수 선택'),
            items: widget.players
                .map(
                  (id) => DropdownMenuItem(
                    value: id,
                    child: Text(widget.displayMap[id] ?? id),
                  ),
                )
                .toList(),
            onChanged: (val) => setState(() => inPlayer = val),
          ),
          TextField(
            decoration: const InputDecoration(labelText: '메모'),
            onChanged: (val) => memo = val,
          ),
          const SizedBox(height: 8),
          FilledButton(
            onPressed: (outPlayer == null || inPlayer == null)
                ? null
                : () {
                    widget.onSave(outPlayer!, inPlayer!, memo);
                    Navigator.pop(context);
                  },
            child: const Text('저장'),
          ),
        ],
      ),
    );
  }
}
