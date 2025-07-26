import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

import '../../models/match_event_model.dart';
import '../../services/firestore/match_service.dart';

import 'widgets/record_goal_modal.dart';
import 'widgets/record_change_modal.dart';
import 'widgets/record_edit_modal.dart';
import 'widgets/record_tile.dart';

class MatchDetailPage extends StatefulWidget {
  final MatchEvent event;
  const MatchDetailPage({super.key, required this.event});

  @override
  State<MatchDetailPage> createState() => _MatchDetailPageState();
}

class _MatchDetailPageState extends State<MatchDetailPage> {
  late final MatchService _matchService;
  Map<String, String> displayMap = {}; // userId → '7번 길동'

  @override
  void initState() {
    super.initState();
    _matchService = MatchService(widget.event.id);
    _loadMemberDisplayMap();
  }

  Future<void> _loadMemberDisplayMap() async {
    final matchDoc = await FirebaseFirestore.instance
        .collection('matches')
        .doc(widget.event.id)
        .get();
    final matchData = matchDoc.data() as Map<String, dynamic>?;
    if (matchData == null) return;

    final participants = (matchData['participants'] as List?) ?? [];
    final attendingIds = participants
        .where((p) => p is Map && p['status'] == 'attending')
        .map((p) => (p as Map)['userId'] as String)
        .toList();

    if (attendingIds.isEmpty) return;

    final Map<String, String> temp = {};
    for (var i = 0; i < attendingIds.length; i += 10) {
      final chunk = attendingIds.sublist(
        i,
        i + 10 > attendingIds.length ? attendingIds.length : i + 10,
      );
      final memberSnap = await FirebaseFirestore.instance
          .collection('members')
          .where(FieldPath.documentId, whereIn: chunk)
          .get();
      for (var doc in memberSnap.docs) {
        final num = doc['number']?.toString() ?? '';
        final uniform = doc['uniformName'] ?? doc['name'] ?? doc.id;
        temp[doc.id] = '${num}번 $uniform';
      }
    }

    if (mounted) {
      setState(() {
        displayMap = temp;
      });
    }
  }

  int _calcOffset(Timestamp? startTime) {
    if (startTime == null) return 0;
    return DateTime.now().difference(startTime.toDate()).inMinutes;
  }

  void _openGoalModal(List<String> players, Timestamp? startTime) {
    showGoalModal(
      context,
      RecordGoalModal(
        players: players,
        displayMap: displayMap,
        onSave: (playerId, memo) async {
          await _matchService.addGoalRecord(
            playerId,
            memo,
            _calcOffset(startTime),
          );
        },
      ),
    );
  }

  void _openChangeModal(List<String> players, Timestamp? startTime) {
    showChangeModal(
      context,
      RecordChangeModal(
        players: players,
        displayMap: displayMap,
        onSave: (outId, inId, memo) async {
          await _matchService.addChangeRecord(
            outId,
            inId,
            memo,
            _calcOffset(startTime),
          );
        },
      ),
    );
  }

  void _openEditModal(
    Map<String, dynamic> record,
    String recordId,
    List<String> players,
  ) {
    showEditModal(
      context,
      RecordEditModal(
        displayMap: displayMap,
        players: players,
        record: record,
        onSave: ({newPlayer, newOut, newIn, required newMemo}) async {
          final ref = FirebaseFirestore.instance
              .collection('matches')
              .doc(widget.event.id)
              .collection('records')
              .doc(recordId);

          if (record['type'] == 'goal') {
            await ref.update({
              'playerName': newPlayer ?? record['playerName'],
              'memo': newMemo,
            });
          } else if (record['type'] == 'change') {
            await ref.update({
              'outPlayerName': newOut ?? record['outPlayerName'],
              'inPlayerName': newIn ?? record['inPlayerName'],
              'memo': newMemo,
            });
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('${widget.event.teamName} 상세')),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('matches')
            .doc(widget.event.id)
            .snapshots(),
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final data = snap.data!.data() as Map<String, dynamic>? ?? {};
          final participants = (data['participants'] as List?) ?? [];
          final gameStatus = data['gameStatus'] ?? 'notStarted';
          final startTime = data['startTime'] as Timestamp?;
          final attendingPlayers = participants
              .where((p) => p is Map && p['status'] == 'attending')
              .map((p) => (p as Map)['userId'] as String)
              .toList();

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '경기 상태: $gameStatus',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    if (gameStatus == 'notStarted')
                      FilledButton.icon(
                        onPressed: () =>
                            _matchService.updateGameStatus('inProgress'),
                        icon: const Icon(Icons.play_arrow),
                        label: const Text('경기 시작'),
                      ),
                    if (gameStatus == 'inProgress')
                      FilledButton.icon(
                        onPressed: () =>
                            _matchService.updateGameStatus('finished'),
                        icon: const Icon(Icons.flag),
                        label: const Text('경기 종료'),
                      ),
                  ],
                ),
                const Divider(height: 32),
                Row(
                  children: [
                    ElevatedButton(
                      onPressed: () =>
                          _openGoalModal(attendingPlayers, startTime),
                      child: const Text('⚽ 득점 기록'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () =>
                          _openChangeModal(attendingPlayers, startTime),
                      child: const Text('🔄 교체 기록'),
                    ),
                  ],
                ),
                const Divider(height: 32),
                Text(
                  '📋 실시간 경기 기록',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('matches')
                      .doc(widget.event.id)
                      .collection('records')
                      .orderBy('createdAt', descending: false)
                      .snapshots(),
                  builder: (context, recSnap) {
                    if (!recSnap.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (recSnap.data!.docs.isEmpty) {
                      return const Text('기록 없음');
                    }
                    return ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: recSnap.data!.docs.length,
                      itemBuilder: (ctx, i) {
                        final doc = recSnap.data!.docs[i];
                        final record = doc.data() as Map<String, dynamic>;
                        return RecordTile(
                          record: record,
                          displayMap: displayMap,
                          onEdit: () =>
                              _openEditModal(record, doc.id, attendingPlayers),
                          onDelete: () async =>
                              await _matchService.deleteRecord(doc.id),
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
