import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../models/match_event_model.dart';
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
  DateTime? roundStartTime;
  Timer? _timer;
  int elapsedSeconds = 0;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer(DateTime start) {
    _timer?.cancel();
    roundStartTime = start;
    elapsedSeconds = DateTime.now().difference(start).inSeconds;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        elapsedSeconds = DateTime.now().difference(roundStartTime!).inSeconds;
      });
    });
  }

  String _formatDuration(Duration d) {
    String two(int n) => n.toString().padLeft(2, '0');
    return "${two(d.inMinutes.remainder(60))}:${two(d.inSeconds.remainder(60))}";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('📋 ${widget.event.teamName}')),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('matches')
            .doc(widget.event.id)
            .snapshots(),
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final data = snap.data!.data() as Map<String, dynamic>;
          final participants = (data['participants'] ?? []) as List;
          final recruitStatus = data['recruitStatus'] ?? 'waiting';

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 상단 정보
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('모집 상태: $recruitStatus'),
                    Text('참석자 수: ${participants.length} 명'),
                    const SizedBox(height: 8),
                    TeamSelectButton(matchId: widget.event.id),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.add),
                      label: const Text('라운드 추가'),
                      onPressed: () async {
                        final newDoc = FirebaseFirestore.instance
                            .collection('matches')
                            .doc(widget.event.id)
                            .collection('rounds')
                            .doc();
                        await newDoc.set({
                          'status': 'notStarted',
                          'startTime': null,
                          'endTime': null,
                          'score': {'home': 0, 'away': 0},
                        });
                      },
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),

              // 라운드 선택
              RoundSelector(
                matchId: widget.event.id,
                onSelected: (roundId) {
                  setState(() => selectedRoundId = roundId);
                },
              ),

              if (selectedRoundId != null) ...[
                // 라운드 상태 관리
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: StreamBuilder<DocumentSnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('matches')
                        .doc(widget.event.id)
                        .collection('rounds')
                        .doc(selectedRoundId!)
                        .snapshots(),
                    builder: (context, roundSnap) {
                      if (!roundSnap.hasData || !roundSnap.data!.exists) {
                        return const SizedBox();
                      }
                      final roundData =
                          roundSnap.data!.data() as Map<String, dynamic>;
                      final status = roundData['status'] ?? 'notStarted';
                      final startTimeTS = roundData['startTime'] as Timestamp?;
                      final startTime = startTimeTS?.toDate();
                      if (startTime != null && status == 'inProgress') {
                        _startTimer(startTime);
                      } else if (status != 'inProgress') {
                        _timer?.cancel();
                      }

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              ElevatedButton.icon(
                                icon: const Icon(Icons.play_arrow),
                                label: const Text('라운드 시작'),
                                onPressed: status == 'notStarted'
                                    ? () async {
                                        final now = DateTime.now();
                                        await MatchService.updateRoundStatus(
                                          widget.event.id,
                                          selectedRoundId!,
                                          'inProgress',
                                        );
                                        await FirebaseFirestore.instance
                                            .collection('matches')
                                            .doc(widget.event.id)
                                            .collection('rounds')
                                            .doc(selectedRoundId!)
                                            .update({
                                              'startTime': Timestamp.fromDate(
                                                now,
                                              ),
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
                                          widget.event.id,
                                          selectedRoundId!,
                                          'finished',
                                        );
                                        await FirebaseFirestore.instance
                                            .collection('matches')
                                            .doc(widget.event.id)
                                            .collection('rounds')
                                            .doc(selectedRoundId!)
                                            .update({
                                              'endTime': Timestamp.now(),
                                            });
                                      }
                                    : null,
                              ),
                              const SizedBox(width: 12),
                              Expanded(child: Text('상태: $status')),
                            ],
                          ),
                          if (startTime != null) ...[
                            Text(
                              '시작: ${DateFormat('HH:mm:ss').format(startTime)}',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ],
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
                      );
                    },
                  ),
                ),

                // 득점/교체 기록 버튼
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: RecordButtons(
                    onAddGoal: () {
                      showRecordGoalModal(
                        context,
                        widget.event.id,
                        selectedRoundId!,
                      );
                    },
                    onAddChange: () {
                      showRecordChangeModal(
                        context,
                        widget.event.id,
                        selectedRoundId!,
                      );
                    },
                  ),
                ),

                // 기록 리스트
                Expanded(
                  child: RecordList(
                    matchId: widget.event.id,
                    roundId: selectedRoundId!,
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}
