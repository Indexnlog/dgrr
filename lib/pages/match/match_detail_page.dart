import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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

              // 라운드별 기록 관리
              if (selectedRoundId != null) ...[
                // 라운드 상태 관리 버튼
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

                      return Row(
                        children: [
                          ElevatedButton.icon(
                            icon: const Icon(Icons.play_arrow),
                            label: const Text('라운드 시작'),
                            onPressed: status == 'notStarted'
                                ? () async {
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
                                        .update({'startTime': Timestamp.now()});
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
                                        .update({'endTime': Timestamp.now()});
                                  }
                                : null,
                          ),
                          const SizedBox(width: 12),
                          Text('상태: $status'),
                        ],
                      );
                    },
                  ),
                ),

                // 득점/교체 기록 버튼
                RecordButtons(
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
