import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RecordList extends StatelessWidget {
  final String matchId;
  final String roundId;

  const RecordList({super.key, required this.matchId, required this.roundId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('matches')
          .doc(matchId)
          .collection('rounds')
          .doc(roundId)
          .collection('records')
          .orderBy('timeOffset', descending: false)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('기록이 없습니다.'));
        }

        final records = snapshot.data!.docs;

        return ListView.separated(
          itemCount: records.length,
          separatorBuilder: (context, index) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final doc = records[index];
            final data = doc.data() as Map<String, dynamic>;

            final type = data['type'] ?? '';
            final timeOffset = data['timeOffset'] ?? 0;

            // 🏷️ UI 분기
            String title = '';
            if (type == 'goal') {
              title = data['playerName'] ?? '';
            } else if (type == 'change') {
              final outName = data['outPlayerName'] ?? '';
              final inName = data['inPlayerName'] ?? '';
              title = '$outName ➡ $inName';
            }

            return ListTile(
              leading: type == 'goal'
                  ? const Icon(Icons.sports_soccer, color: Colors.green)
                  : const Icon(Icons.compare_arrows, color: Colors.blue),
              title: Text(title),
              subtitle: Text('$timeOffset분 경과'),
              onLongPress: () => _showDeleteSheet(context, doc.reference),
            );
          },
        );
      },
    );
  }

  /// 🔥 삭제 모달
  void _showDeleteSheet(BuildContext context, DocumentReference ref) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('이 기록 삭제'),
                onTap: () async {
                  await ref.delete();
                  if (context.mounted) Navigator.pop(context);
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }
}
