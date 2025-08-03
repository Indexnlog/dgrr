import 'package:flutter/material.dart';

class RecordGoalModal extends StatefulWidget {
  final List<String> players;
  final Map<String, String> displayMap;
  final void Function(String playerId, String memo) onSave;

  const RecordGoalModal({
    super.key,
    required this.players,
    required this.displayMap,
    required this.onSave,
  });

  @override
  State<RecordGoalModal> createState() => _RecordGoalModalState();
}

class _RecordGoalModalState extends State<RecordGoalModal> {
  String? selectedPlayer;
  String memo = '';

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Material(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '⚽ 득점 기록 추가',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                DropdownButton<String>(
                  value: selectedPlayer,
                  isExpanded: true,
                  hint: const Text('선수 선택'),
                  items: widget.players.map((id) {
                    return DropdownMenuItem(
                      value: id,
                      child: Text(widget.displayMap[id] ?? id),
                    );
                  }).toList(),
                  onChanged: (val) => setState(() => selectedPlayer = val),
                ),
                TextField(
                  decoration: const InputDecoration(labelText: '메모'),
                  onChanged: (val) => memo = val,
                ),
                const SizedBox(height: 12),
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
          ),
        ),
      ),
    );
  }
}

/// 호출 헬퍼
Future<void> showGoalModal(BuildContext context, Widget modalContent) {
  return showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: '',
    barrierColor: Colors.black54,
    pageBuilder: (ctx, anim1, anim2) => modalContent,
    transitionDuration: const Duration(milliseconds: 300),
    transitionBuilder: (ctx, anim, sec, child) {
      final curve = CurvedAnimation(parent: anim, curve: Curves.easeOut);
      return FadeTransition(
        opacity: curve,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 1),
            end: Offset.zero,
          ).animate(curve),
          child: child,
        ),
      );
    },
  );
}
