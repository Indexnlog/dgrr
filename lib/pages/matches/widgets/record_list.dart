import 'package:flutter/material.dart';
import '../../models/match/match_event_model.dart'; // ← 모델 경로 확인 필요

class RecordList extends StatelessWidget {
  final List<MatchEventModel> records;

  const RecordList({super.key, required this.records});

  @override
  Widget build(BuildContext context) {
    if (records.isEmpty) {
      return const Center(child: Text('기록이 없습니다.'));
    }

    return ListView.separated(
      itemCount: records.length,
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final data = records[index];

        // 🏷️ UI 분기
        String title = '';
        if (data.type == 'goal') {
          title = data.playerName ?? '';
        } else if (data.type == 'change') {
          final outName = data.outPlayerName ?? '';
          final inName = data.inPlayerName ?? '';
          title = '$outName ➡ $inName';
        }

        return ListTile(
          leading: data.type == 'goal'
              ? const Icon(Icons.sports_soccer, color: Colors.green)
              : const Icon(Icons.compare_arrows, color: Colors.blue),
          title: Text(title),
          subtitle: Text('${data.timeOffset ?? 0}분 경과'),
          onLongPress: () => _showDeleteSheet(context, data.id),
        );
      },
    );
  }

  /// 🔥 삭제 모달
  void _showDeleteSheet(BuildContext context, String? recordId) {
    if (recordId == null) return;

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
                  // 이 부분은 너가 delete 로직 구현한 곳으로 연결해줘야 해
                  // 예시:
                  // await MatchService(matchId, roundId).deleteRecord(recordId);
                  Navigator.pop(context);
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
