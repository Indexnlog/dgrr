import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/match/match_event_model.dart';
import '../../services/firestore/match_service.dart';
import 'widgets/round_selector.dart';
import 'widgets/record_buttons.dart';
import 'widgets/record_list.dart';
import 'widgets/team_select_button.dart';
import 'widgets/record_goal_modal.dart';
import 'widgets/record_change_modal.dart';

class MatchDetailPage extends StatefulWidget {
  final String matchId;
  const MatchDetailPage({super.key, required this.matchId});

  @override
  State<MatchDetailPage> createState() => _MatchDetailPageState();
}

class _MatchDetailPageState extends State<MatchDetailPage> {
  String? selectedRoundId;
  String selectedTeam = 'home';
  StreamSubscription<QuerySnapshot>? _recordSub;
  List<MatchEventModel> _records = [];

  @override
  void dispose() {
    _recordSub?.cancel(); // ✅ null-safe 처리
    super.dispose();
  }

  void _loadRecords() {
    if (selectedRoundId == null) return;
    _recordSub?.cancel(); // ✅ 이전 구독 종료
    _recordSub = FirebaseFirestore.instance
        .collection('matches')
        .doc(widget.matchId)
        .collection('rounds')
        .doc(selectedRoundId)
        .collection('records')
        .orderBy('createdAt')
        .snapshots()
        .listen((snapshot) {
          final newRecords = snapshot.docs
              .map((doc) => MatchEventModel.fromDoc(doc))
              .toList();
          setState(() {
            _records = newRecords;
          });
        });
  }

  void _showRecordGoalModal() async {
    await showGoalModal(
      context,
      RecordGoalModal(
        players: ['1', '2'],
        displayMap: {'1': '지수', '2': '하은'},
        onSave: (playerName, memo) async {
          if (selectedRoundId == null) return;
          final offset = DateTime.now().minute;
          await MatchService(
            widget.matchId,
            selectedRoundId!,
          ).addGoalRecord(playerName, memo, offset, selectedTeam);
        },
      ),
    );
  }

  void _showRecordChangeModal() async {
    await showChangeModal(
      context,
      RecordChangeModal(
        players: ['1', '2'],
        displayMap: {'1': '지수', '2': '하은'},
        onSave: (outPlayer, inPlayer, memo) async {
          if (selectedRoundId == null) return;
          final offset = DateTime.now().minute;
          await MatchService(
            widget.matchId,
            selectedRoundId!,
          ).addChangeRecord(outPlayer, inPlayer, memo, offset, selectedTeam);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isReady = selectedRoundId != null;

    return Scaffold(
      appBar: AppBar(title: const Text('매치 상세')),
      body: Column(
        children: [
          RoundSelector(
            matchId: widget.matchId,
            selectedRoundId: selectedRoundId,
            onRoundSelected: (roundId) {
              setState(() {
                selectedRoundId = roundId;
              });
              _loadRecords();
            },
          ),
          TeamSelectButton(
            selectedTeam: selectedTeam,
            onTeamChanged: (team) => setState(() => selectedTeam = team),
          ),
          RecordButtons(
            onAddGoal: isReady ? _showRecordGoalModal : () {},
            onAddChange: isReady ? _showRecordChangeModal : () {},
          ),
          Expanded(child: RecordList(records: _records)),
        ],
      ),
    );
  }
}
