import 'package:flutter/material.dart';

class RecordEditModal extends StatefulWidget {
  final Map<String, String> displayMap;
  final List<String> players;
  final Map<String, dynamic> record;
  final void Function({
    String? newPlayer,
    String? newOut,
    String? newIn,
    required String newMemo,
  })
  onSave;

  const RecordEditModal({
    super.key,
    required this.displayMap,
    required this.players,
    required this.record,
    required this.onSave,
  });

  @override
  State<RecordEditModal> createState() => _RecordEditModalState();
}

class _RecordEditModalState extends State<RecordEditModal> {
  String? selectedPlayer;
  String? selectedOut;
  String? selectedIn;
  late String memo;

  @override
  void initState() {
    super.initState();
    memo = widget.record['memo'] ?? '';
    if (widget.record['type'] == 'goal') {
      selectedPlayer = widget.record['playerName'];
    } else if (widget.record['type'] == 'change') {
      selectedOut = widget.record['outPlayerName'];
      selectedIn = widget.record['inPlayerName'];
    }
  }

  @override
  Widget build(BuildContext context) {
    final type = widget.record['type'];
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
                Text('기록 수정', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 12),
                if (type == 'goal')
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
                if (type == 'change') ...[
                  DropdownButton<String>(
                    value: selectedOut,
                    isExpanded: true,
                    hint: const Text('OUT 선수'),
                    items: widget.players.map((id) {
                      return DropdownMenuItem(
                        value: id,
                        child: Text(widget.displayMap[id] ?? id),
                      );
                    }).toList(),
                    onChanged: (val) => setState(() => selectedOut = val),
                  ),
                  DropdownButton<String>(
                    value: selectedIn,
                    isExpanded: true,
                    hint: const Text('IN 선수'),
                    items: widget.players.map((id) {
                      return DropdownMenuItem(
                        value: id,
                        child: Text(widget.displayMap[id] ?? id),
                      );
                    }).toList(),
                    onChanged: (val) => setState(() => selectedIn = val),
                  ),
                ],
                TextField(
                  decoration: const InputDecoration(labelText: '메모'),
                  controller: TextEditingController(text: memo),
                  onChanged: (val) => memo = val,
                ),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: () {
                    widget.onSave(
                      newPlayer: selectedPlayer,
                      newOut: selectedOut,
                      newIn: selectedIn,
                      newMemo: memo,
                    );
                    Navigator.pop(context);
                  },
                  child: const Text('수정 완료'),
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
Future<void> showEditModal(BuildContext context, Widget modalContent) {
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
