import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/match_event_model.dart';
import '../../widgets/team_select_bottom_sheet.dart'; // 팀 선택 BottomSheet 위젯

class MatchDetailPage extends StatefulWidget {
  final MatchEvent event;
  const MatchDetailPage({super.key, required this.event});

  @override
  State<MatchDetailPage> createState() => _MatchDetailPageState();
}

class _MatchDetailPageState extends State<MatchDetailPage> {
  bool _bottomSheetShown = false; // 여러 번 뜨지 않게 방지

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('📋 경기 상세')),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('matches')
            .doc(widget.event.id)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('경기 정보를 불러올 수 없습니다.'));
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;
          final participants = (data['participants'] ?? []) as List;
          final teamId = data['teamId'] as String?;
          final status = data['status'] as String? ?? '대기중';

          // ✅ 참석자 7명 이상 & 팀 미지정 → BottomSheet 자동 호출
          if (!_bottomSheetShown &&
              participants.length >= 7 &&
              (teamId == null || teamId.isEmpty)) {
            _bottomSheetShown = true;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _showTeamSelectBottomSheet(widget.event.id);
            });
          }

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '경기 상태: $status',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Text('참석자 수: ${participants.length} 명'),
                const SizedBox(height: 12),

                // ✅ 상태 전환 버튼
                ElevatedButton(
                  onPressed: () async {
                    await _toggleMatchStatus(widget.event.id);
                  },
                  child: const Text('경기 상태 전환'),
                ),

                const Divider(height: 32),

                const Text(
                  '참석자 목록',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: ListView.builder(
                    itemCount: participants.length,
                    itemBuilder: (context, index) {
                      return Text('- ${participants[index]}');
                    },
                  ),
                ),

                const Divider(height: 32),

                // ✅ 기록 추가 버튼들
                Row(
                  children: [
                    ElevatedButton.icon(
                      icon: const Icon(Icons.sports_soccer),
                      label: const Text('득점 기록'),
                      onPressed: () {
                        _showRecordGoalModal(widget.event.id);
                      },
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.compare_arrows),
                      label: const Text('교체 기록'),
                      onPressed: () {
                        _showRecordChangeModal(widget.event.id);
                      },
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // ✅ 실시간 경기 기록
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('matches')
                        .doc(widget.event.id)
                        .collection('records')
                        .orderBy('createdAt', descending: false)
                        .snapshots(),
                    builder: (context, snap) {
                      if (snap.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (!snap.hasData || snap.data!.docs.isEmpty) {
                        return const Center(child: Text('기록이 없습니다.'));
                      }
                      final records = snap.data!.docs;
                      return ListView(
                        children: records.map((doc) {
                          final r = doc.data() as Map<String, dynamic>;
                          return ListTile(
                            leading: r['type'] == 'goal'
                                ? const Icon(
                                    Icons.sports_soccer,
                                    color: Colors.green,
                                  )
                                : const Icon(
                                    Icons.compare_arrows,
                                    color: Colors.blue,
                                  ),
                            title: Text('${r['player']}'),
                            subtitle: Text('${r['timeOffset']}분 경과'),
                            onLongPress: () async {
                              // ✅ 롱프레스 시 기록 삭제
                              await doc.reference.delete();
                            },
                          );
                        }).toList(),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 8),

                // ✅ 수동으로 팀 선택 BottomSheet 열기 (필요 시)
                ElevatedButton(
                  onPressed: () {
                    _showTeamSelectBottomSheet(widget.event.id);
                  },
                  child: const Text('상대팀 선택 (수동)'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ✅ 팀 선택 BottomSheet
  void _showTeamSelectBottomSheet(String matchId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return TeamSelectBottomSheet(
          onTeamSelected: (selectedTeamId) {
            _updateMatchWithTeamId(matchId, selectedTeamId);
          },
        );
      },
    );
  }

  // ✅ Firestore 팀 정보 업데이트
  Future<void> _updateMatchWithTeamId(String matchId, String teamId) async {
    await FirebaseFirestore.instance.collection('matches').doc(matchId).update({
      'teamId': teamId,
      'status': 'confirmed',
    });
  }

  // ✅ 상태 전환 함수
  Future<void> _toggleMatchStatus(String matchId) async {
    final doc = await FirebaseFirestore.instance
        .collection('matches')
        .doc(matchId)
        .get();
    if (!doc.exists) return;

    final currentStatus = doc['status'] ?? '대기중';
    final now = DateTime.now();
    String newStatus;
    final updates = <String, dynamic>{};

    if (currentStatus == '대기중') {
      newStatus = '진행중';
      updates['startTime'] = now;
    } else if (currentStatus == '진행중') {
      newStatus = '종료';
      updates['endTime'] = now;
    } else {
      newStatus = '대기중';
      updates.remove('startTime');
      updates.remove('endTime');
    }
    updates['status'] = newStatus;

    await FirebaseFirestore.instance
        .collection('matches')
        .doc(matchId)
        .update(updates);
  }

  // ✅ 기록 추가 함수
  Future<void> _addMatchRecord(
    String matchId,
    String type,
    String playerInfo,
  ) async {
    final matchDoc = await FirebaseFirestore.instance
        .collection('matches')
        .doc(matchId)
        .get();
    if (!matchDoc.exists) return;

    DateTime? startTime = (matchDoc.data()?['startTime'] as Timestamp?)
        ?.toDate();
    int offset = 0;
    if (startTime != null) {
      offset = DateTime.now().difference(startTime).inMinutes;
    }

    await FirebaseFirestore.instance
        .collection('matches')
        .doc(matchId)
        .collection('records')
        .add({
          'type': type,
          'player': playerInfo,
          'timeOffset': offset,
          'createdAt': Timestamp.now(),
        });
  }

  // ✅ 득점 모달
  void _showRecordGoalModal(String matchId) {
    String playerName = '';
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('득점 기록'),
          content: TextField(
            decoration: const InputDecoration(labelText: '선수 닉네임'),
            onChanged: (v) => playerName = v,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('취소'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (playerName.trim().isEmpty) return;
                await _addMatchRecord(matchId, 'goal', playerName);
                if (mounted) Navigator.pop(context);
              },
              child: const Text('저장'),
            ),
          ],
        );
      },
    );
  }

  // ✅ 교체 모달
  void _showRecordChangeModal(String matchId) {
    String outPlayer = '';
    String inPlayer = '';
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('교체 기록'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                decoration: const InputDecoration(labelText: 'OUT 선수'),
                onChanged: (v) => outPlayer = v,
              ),
              TextField(
                decoration: const InputDecoration(labelText: 'IN 선수'),
                onChanged: (v) => inPlayer = v,
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
                if (outPlayer.trim().isEmpty || inPlayer.trim().isEmpty) return;
                await _addMatchRecord(
                  matchId,
                  'change',
                  '$outPlayer → $inPlayer',
                );
                if (mounted) Navigator.pop(context);
              },
              child: const Text('저장'),
            ),
          ],
        );
      },
    );
  }
}
