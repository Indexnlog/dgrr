import 'package:flutter/material.dart';

class RecordChangeModal extends StatefulWidget {
  final List<String> players;
  final Map<String, String> displayMap;
  final void Function(String outPlayerId, String inPlayerId, String memo)
  onSave;

  const RecordChangeModal({
    super.key,
    required this.players,
    required this.displayMap,
    required this.onSave,
  });

  @override
  State<RecordChangeModal> createState() => _RecordChangeModalState();
}

class _RecordChangeModalState extends State<RecordChangeModal> {
  String? outPlayer;
  String? inPlayer;
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
                  '🔄 교체 기록 추가',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                DropdownButton<String>(
                  value: outPlayer,
                  isExpanded: true,
                  hint: const Text('OUT 선수 선택'),
                  items: widget.players.map((id) {
                    return DropdownMenuItem(
                      value: id,
                      child: Text(widget.displayMap[id] ?? id),
                    );
                  }).toList(),
                  onChanged: (val) => setState(() => outPlayer = val),
                ),
                DropdownButton<String>(
                  value: inPlayer,
                  isExpanded: true,
                  hint: const Text('IN 선수 선택'),
                  items: widget.players.map((id) {
                    return DropdownMenuItem(
                      value: id,
                      child: Text(widget.displayMap[id] ?? id),
                    );
                  }).toList(),
                  onChanged: (val) => setState(() => inPlayer = val),
                ),
                TextField(
                  decoration: const InputDecoration(labelText: '메모'),
                  onChanged: (val) => memo = val,
                ),
                const SizedBox(height: 12),
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
          ),
        ),
      ),
    );
  }
}

/// 호출 헬퍼
Future<void> showChangeModal(BuildContext context, Widget modalContent) {
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
