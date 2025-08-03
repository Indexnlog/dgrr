import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../services/firestore/match_service.dart';

/// ✅ 득점 모달
Future<void> showRecordGoalModal(
  BuildContext context,
  String matchId,
  String roundId,
) async {
  String playerName = '';
  String selectedTeam = 'home';

  await showDialog(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setModalState) {
          return AlertDialog(
            title: const Text('득점 기록'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  decoration: const InputDecoration(labelText: '선수 닉네임'),
                  onChanged: (v) => playerName = v,
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: selectedTeam,
                  items: const [
                    DropdownMenuItem(value: 'home', child: Text('홈 팀')),
                    DropdownMenuItem(value: 'away', child: Text('원정 팀')),
                  ],
                  onChanged: (val) {
                    if (val != null) {
                      setModalState(() {
                        selectedTeam = val;
                      });
                    }
                  },
                  decoration: const InputDecoration(labelText: '팀 선택'),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('취소'),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (playerName.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('선수 이름을 입력해주세요')),
                    );
                    return;
                  }

                  // ✅ startTime 가져오기
                  final roundDoc = await FirebaseFirestore.instance
                      .collection('matches')
                      .doc(matchId)
                      .collection('rounds')
                      .doc(roundId)
                      .get();

                  final roundData = roundDoc.data() as Map<String, dynamic>?;
                  if (roundData == null || roundData['startTime'] == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('라운드가 시작되지 않았습니다!')),
                    );
                    return;
                  }

                  final startTime = (roundData['startTime'] as Timestamp)
                      .toDate();
                  final now = DateTime.now();
                  final offset = now.difference(startTime).inMinutes;

                  await MatchService(
                    matchId,
                    roundId,
                  ).addGoalRecord(playerName, '', offset, selectedTeam);

                  if (context.mounted) Navigator.pop(context);
                },
                child: const Text('저장'),
              ),
            ],
          );
        },
      );
    },
  );
}

/// ✅ 교체 모달
Future<void> showRecordChangeModal(
  BuildContext context,
  String matchId,
  String roundId,
) async {
  String outPlayer = '';
  String inPlayer = '';
  String selectedTeam = 'home';

  await showDialog(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setModalState) {
          return AlertDialog(
            title: const Text('교체 기록'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  decoration: const InputDecoration(labelText: 'OUT 선수'),
                  onChanged: (v) => outPlayer = v,
                ),
                const SizedBox(height: 8),
                TextField(
                  decoration: const InputDecoration(labelText: 'IN 선수'),
                  onChanged: (v) => inPlayer = v,
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: selectedTeam,
                  items: const [
                    DropdownMenuItem(value: 'home', child: Text('홈 팀')),
                    DropdownMenuItem(value: 'away', child: Text('원정 팀')),
                  ],
                  onChanged: (val) {
                    if (val != null) {
                      setModalState(() {
                        selectedTeam = val;
                      });
                    }
                  },
                  decoration: const InputDecoration(labelText: '팀 선택'),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('취소'),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (outPlayer.trim().isEmpty || inPlayer.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('OUT/IN 선수 이름을 입력해주세요')),
                    );
                    return;
                  }

                  // ✅ startTime 가져오기
                  final roundDoc = await FirebaseFirestore.instance
                      .collection('matches')
                      .doc(matchId)
                      .collection('rounds')
                      .doc(roundId)
                      .get();

                  final roundData = roundDoc.data() as Map<String, dynamic>?;
                  if (roundData == null || roundData['startTime'] == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('라운드가 시작되지 않았습니다!')),
                    );
                    return;
                  }

                  final startTime = (roundData['startTime'] as Timestamp)
                      .toDate();
                  final now = DateTime.now();
                  final offset = now.difference(startTime).inMinutes;

                  await MatchService(matchId, roundId).addChangeRecord(
                    outPlayer,
                    inPlayer,
                    '',
                    offset,
                    selectedTeam,
                  );

                  if (context.mounted) Navigator.pop(context);
                },
                child: const Text('저장'),
              ),
            ],
          );
        },
      );
    },
  );
}
