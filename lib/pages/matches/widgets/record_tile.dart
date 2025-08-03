import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // ✅ 추가

class RecordTile extends StatelessWidget {
  final Map<String, dynamic> record;
  final Map<String, String> displayMap;
  final void Function() onEdit;
  final void Function() onDelete;

  const RecordTile({
    super.key,
    required this.record,
    required this.displayMap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final type = record['type'];
    final createdAt = (record['createdAt'] as Timestamp?)?.toDate();
    final offset = record['timeOffset'] ?? 0;
    final timeText = createdAt != null
        ? DateFormat('HH:mm').format(createdAt)
        : '?';
    final memo = record['memo'] ?? '';

    Widget tile;
    if (type == 'goal') {
      final uid = record['playerName'];
      tile = ListTile(
        leading: const Icon(Icons.sports_soccer, color: Colors.green),
        title: Text('$timeText (${offset}분) : ${displayMap[uid] ?? uid} 득점'),
        subtitle: memo.isNotEmpty ? Text('메모: $memo') : null,
      );
    } else if (type == 'change') {
      final out = record['outPlayerName'];
      final inn = record['inPlayerName'];
      tile = ListTile(
        leading: const Icon(Icons.sync_alt, color: Colors.blue),
        title: Text(
          '$timeText (${offset}분) : ${displayMap[out] ?? out} ➡ ${displayMap[inn] ?? inn} 교체',
        ),
        subtitle: memo.isNotEmpty ? Text('메모: $memo') : null,
      );
    } else {
      tile = const SizedBox.shrink();
    }

    return GestureDetector(
      onLongPress: () async {
        final action = await showModalBottomSheet<String>(
          context: context,
          builder: (ctx) {
            return SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    leading: const Icon(Icons.edit),
                    title: const Text('메모 수정'),
                    onTap: () => Navigator.pop(ctx, 'edit'),
                  ),
                  ListTile(
                    leading: const Icon(Icons.delete),
                    title: const Text('기록 삭제'),
                    onTap: () => Navigator.pop(ctx, 'delete'),
                  ),
                ],
              ),
            );
          },
        );
        if (action == 'edit') {
          onEdit();
        } else if (action == 'delete') {
          onDelete();
        }
      },
      child: Card(margin: const EdgeInsets.symmetric(vertical: 4), child: tile),
    );
  }
}
