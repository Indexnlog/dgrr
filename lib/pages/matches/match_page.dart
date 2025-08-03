import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

import '../../models/match/match_event_model.dart';
import 'widgets/round_selector.dart';
import 'widgets/record_buttons.dart';
import 'widgets/record_modals.dart';
import 'widgets/record_list.dart';
import 'widgets/team_select_button.dart';
import '../../services/firestore/match_service.dart';

class MatchDetailPage extends StatefulWidget {
  final MatchEvent event;
  const MatchDetailPage({super.key, required this.event});

  @override
  State<MatchDetailPage> createState() => _MatchDetailPageState();
}

class _MatchDetailPageState extends State<MatchDetailPage> {
  String? selectedRoundId;
  Timer? _timer;
  int elapsedSeconds = 0;
  DateTime? roundStartTime;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer(DateTime start) {
    _timer?.cancel();
    roundStartTime = start;
    int diff = DateTime.now().difference(start).inSeconds;
    elapsedSeconds = diff < 0 ? 0 : diff;

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {
        int newDiff = DateTime.now().difference(roundStartTime!).inSeconds;
        elapsedSeconds = newDiff < 0 ? 0 : newDiff;
      });
    });
  }

  void _startTimerIfNeeded(String status, Timestamp? startTimeTS) {
    if (status == 'inProgress' && startTimeTS != null) {
      final startTime = startTimeTS.toDate();
      if (_timer == null || !_timer!.isActive) {
        _startTimer(startTime);
      }
    } else {
      _timer?.cancel();
      _timer = null;
    }

    if (status == 'finished') {
      _timer?.cancel();
      _timer = null;
    }
  }

  String _formatDuration(Duration d) {
    String two(int n) => n.toString().padLeft(2, '0');
    return "${two(d.inMinutes.remainder(60))}:${two(d.inSeconds.remainder(60))}";
  }

  @override
  Widget build(BuildContext context) {
    final matchRef = FirebaseFirestore.instance
        .collection('teams')
        .doc(widget.event.teamId)
        .collection('matches')
        .doc(widget.event.id);

    return Scaffold(
      appBar: AppBar(title: Text('📋 ${widget.event.teamName}')),
      body: StreamBuilder<DocumentSnapshot>(
        stream: matchRef.snapshots(),
        builder: (context, matchSnap) {
          if (!matchSnap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = matchSnap.data!.data() as Map<String, dynamic>;
          final participants = (data['participants'] ?? []) as List;
          final recruitStatus = data['recruitStatus'] ?? 'waiting';

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      recruitStatus == 'confirmed'
                          ? '✅ 경기 확정됨'
                          : '⏳ 상대팀 미정 / 인원 미달',
                      style: TextStyle(
                        color: recruitStatus == 'confirmed'
                            ? Colors.green
                            : Colors.orange,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text('참석자 수: ${participants.length} 명'),
                    const SizedBox(height: 8),
                    TeamSelectButton(matchId: widget.event.id),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.add),
                      label: const Text('라운드 추가'),
                      onPressed: () async {
                        final newDoc = matchRef.collection('rounds').doc();
                        await newDoc.set({
                          'status': 'notStarted',
                          'startTime': null,
                          'endTime': null,
                          'score': {'home': 0, 'away': 0},
                          'createdAt': Timestamp.now(),
                        });
                      },
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              RoundSelector(
                matchId: widget.event.id,
                teamId: widget.event.teamId,
                onSelected: (roundId) {
                  setState(() => selectedRoundId = roundId);
                },
              ),
              if (selectedRoundId != null) _buildRoundSection(matchRef),
            ],
          );
        },
      ),
    );
  }

  Widget _buildRoundSection(DocumentReference matchRef) {
    final roundRef = matchRef.collection('rounds').doc(selectedRoundId!);

    return StreamBuilder<DocumentSnapshot>(
      stream: roundRef.snapshots(),
      builder: (context, roundSnap) {
        if (!roundSnap.hasData || !roundSnap.data!.exists) {
          return const SizedBox.shrink();
        }

        final round = roundSnap.data!.data() as Map<String, dynamic>;
        final status = round['status'] ?? 'notStarted';
        final startTimeTS = round['startTime'] as Timestamp?;
        final startTime = startTimeTS?.toDate();

        _startTimerIfNeeded(status, startTimeTS);

        return Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    ElevatedButton.icon(
                      icon: const Icon(Icons.play_arrow),
                      label: const Text('라운드 시작'),
                      onPressed: status == 'notStarted'
                          ? () async {
                              final now = DateTime.now();
                              await MatchService.updateRoundStatus(
                                widget.event.teamId,
                                widget.event.id,
                                selectedRoundId!,
                                'inProgress',
                              );
                              await roundRef.update({
                                'startTime': Timestamp.fromDate(now),
                              });
                            }
                          : null,
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.stop),
                      label: const Text('라운드 종료'),
                      onPressed: status == 'inProgress'
                          ? () async {
                              await MatchService.updateRoundStatus(
                                widget.event.teamId,
                                widget.event.id,
                                selectedRoundId!,
                                'finished',
                              );
                              await roundRef.update({
                                'endTime': Timestamp.now(),
                              });
                            }
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: Text('상태: $status')),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (startTime != null)
                      Text(
                        '시작: ${DateFormat('HH:mm:ss').format(startTime)}',
                        style: const TextStyle(fontSize: 12),
                      ),
                    if (status == 'inProgress' && roundStartTime != null)
                      Text(
                        '경과: ${_formatDuration(Duration(seconds: elapsedSeconds))}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.red,
                        ),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: RecordButtons(
                  onAddGoal: () {
                    showRecordGoalModal(
                      context,
                      widget.event.teamId,
                      widget.event.id,
                      selectedRoundId!,
                    );
                  },
                  onAddChange: () {
                    showRecordChangeModal(
                      context,
                      widget.event.teamId,
                      widget.event.id,
                      selectedRoundId!,
                    );
                  },
                ),
              ),
              Expanded(
                child: RecordList(
                  teamId: widget.event.teamId,
                  matchId: widget.event.id,
                  roundId: selectedRoundId!,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
