import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/match_event_model.dart';
import 'match_detail_page.dart';
import '../teams/team_page.dart';

class MatchPage extends StatefulWidget {
  const MatchPage({super.key});

  @override
  State<MatchPage> createState() => _MatchPageState();
}

class _MatchPageState extends State<MatchPage> {
  String get _uid => FirebaseAuth.instance.currentUser!.uid;
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(minutes: 1), (timer) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  Color _hexToColor(String? hex) {
    try {
      if (hex == null || hex.isEmpty) return Colors.grey.shade300;
      final buffer = StringBuffer();
      if (hex.length == 6 || hex.length == 7) buffer.write('ff');
      buffer.write(hex.replaceFirst('#', ''));
      return Color(int.parse(buffer.toString(), radix: 16));
    } catch (e) {
      debugPrint('색상 변환 오류: $e');
      return Colors.grey.shade300;
    }
  }

  Future<void> _openMap(String location) async {
    final encoded = Uri.encodeComponent(location);
    final naverMapUrl = Uri.parse('nmap://search?query=$encoded');
    final webUrl = Uri.parse('https://map.naver.com/v5/search/$encoded');
    if (await canLaunchUrl(naverMapUrl)) {
      await launchUrl(naverMapUrl, mode: LaunchMode.externalApplication);
    } else if (await canLaunchUrl(webUrl)) {
      await launchUrl(webUrl, mode: LaunchMode.externalApplication);
    }
  }

  String _calcDDayStr(DateTime date) {
    final now = DateTime.now();
    final diff = date.difference(DateTime(now.year, now.month, now.day)).inDays;
    if (diff == 0) return 'D-Day';
    if (diff > 0) return 'D-$diff';
    return 'D+${diff.abs()}';
  }

  Color _calcDDayColor(int dDay) {
    if (dDay == 0) return Colors.red;
    if (dDay > 0) return (dDay <= 3) ? Colors.orange : Colors.grey;
    return Colors.blueGrey;
  }

  String _calcGameStatusDetailed(
    DateTime matchDate,
    String? startTimeStr,
    String? endTimeStr,
  ) {
    try {
      if (startTimeStr == null || endTimeStr == null) return '시간 정보 없음';
      final startParts = startTimeStr.split(':');
      final endParts = endTimeStr.split(':');
      final start = DateTime(
        matchDate.year,
        matchDate.month,
        matchDate.day,
        int.parse(startParts[0]),
        int.parse(startParts[1]),
      );
      final end = DateTime(
        matchDate.year,
        matchDate.month,
        matchDate.day,
        int.parse(endParts[0]),
        int.parse(endParts[1]),
      );
      final now = DateTime.now();

      if (now.isAfter(end)) {
        return '종료';
      } else if (now.isAfter(start) && now.isBefore(end)) {
        return '진행중';
      } else {
        final diff = start.difference(now);
        if (diff.inHours >= 1) {
          return '시작까지 ${diff.inHours}시간';
        } else {
          return '시작까지 ${diff.inMinutes}분';
        }
      }
    } catch (e) {
      return '상태불명';
    }
  }

  bool _canEdit(Map<String, dynamic> data, String myRole, String myTeam) {
    if (myRole == 'manager') return true;
    return data['teamId'] == myTeam;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('⚽ 매치'),
        actions: [
          IconButton(
            icon: const Icon(Icons.groups),
            tooltip: '상대팀 목록',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const TeamPage()),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(_uid)
            .snapshots(),
        builder: (context, userSnap) {
          if (!userSnap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final udata = userSnap.data!.data() as Map<String, dynamic>;
          final myRole = udata['role'] ?? '';
          final myTeam = udata['teamId'] ?? '';

          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('matches')
                .where('recruitStatus', isEqualTo: 'confirmed')
                .orderBy('date')
                .snapshots(),
            builder: (context, snap) {
              if (!snap.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final docs = snap.data!.docs;
              if (docs.isEmpty) {
                return const Center(child: Text('등록된 매치가 없습니다.'));
              }

              final matches = docs.map((doc) {
                return MatchEvent.fromMap(
                  doc.data() as Map<String, dynamic>,
                  doc.id,
                );
              }).toList();

              return ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: matches.length,
                itemBuilder: (context, index) {
                  final match = matches[index];
                  final dDay = match.date.difference(DateTime.now()).inDays;

                  return FutureBuilder<DocumentSnapshot>(
                    future: FirebaseFirestore.instance
                        .collection('teams')
                        .doc(match.teamId)
                        .get(),
                    builder: (ctx, teamSnap) {
                      Color teamColor = Colors.grey.shade300;
                      String teamName = match.teamName.isNotEmpty
                          ? match.teamName
                          : '상대팀 미지정';
                      String? logoUrl;

                      if (teamSnap.hasData && teamSnap.data!.exists) {
                        final tdata =
                            teamSnap.data!.data() as Map<String, dynamic>;
                        teamColor = _hexToColor(tdata['teamColor']);
                        teamName = tdata['name'] ?? teamName;
                        logoUrl = tdata['logoUrl'];
                      }

                      final gameStatus = _calcGameStatusDetailed(
                        match.date,
                        match.startTime,
                        match.endTime,
                      );

                      return Card(
                        elevation: 3,
                        shadowColor: teamColor.withOpacity(0.5),
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(color: teamColor, width: 1.5),
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => MatchDetailPage(event: match),
                              ),
                            );
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                (logoUrl != null && logoUrl.isNotEmpty)
                                    ? CircleAvatar(
                                        radius: 28,
                                        backgroundImage: NetworkImage(logoUrl),
                                        backgroundColor: teamColor.withOpacity(
                                          0.2,
                                        ),
                                      )
                                    : CircleAvatar(
                                        radius: 28,
                                        backgroundColor: teamColor,
                                        child: const Icon(
                                          Icons.sports_soccer,
                                          color: Colors.white,
                                        ),
                                      ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              'vs $teamName',
                                              style: const TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ),
                                          Chip(
                                            backgroundColor: _calcDDayColor(
                                              dDay,
                                            ),
                                            label: Text(
                                              _calcDDayStr(match.date),
                                              style: const TextStyle(
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Row(
                                        children: [
                                          const Icon(
                                            Icons.place,
                                            size: 18,
                                            color: Colors.grey,
                                          ),
                                          const SizedBox(width: 4),
                                          Expanded(
                                            child: Text(
                                              match.location ?? '',
                                              style: const TextStyle(
                                                fontSize: 14,
                                              ),
                                            ),
                                          ),
                                          IconButton(
                                            icon: const Icon(
                                              Icons.map,
                                              color: Colors.blue,
                                            ),
                                            tooltip: '지도 열기',
                                            onPressed: () {
                                              if (match.location != null &&
                                                  match.location!.isNotEmpty) {
                                                _openMap(match.location!);
                                              }
                                            },
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          const Icon(
                                            Icons.schedule,
                                            size: 18,
                                            color: Colors.grey,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            '${match.startTime ?? ''}~${match.endTime ?? ''}',
                                            style: const TextStyle(
                                              fontSize: 14,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          const Icon(
                                            Icons.sports,
                                            size: 18,
                                            color: Colors.grey,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            '상태: $gameStatus',
                                            style: const TextStyle(
                                              fontSize: 14,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const Divider(height: 16),
                                      StreamBuilder<QuerySnapshot>(
                                        stream: FirebaseFirestore.instance
                                            .collection('matches')
                                            .doc(match.id)
                                            .collection('rounds')
                                            .orderBy(
                                              'startTime',
                                              descending: false,
                                            )
                                            .limit(10)
                                            .snapshots(),
                                        builder: (context, roundSnap) {
                                          if (!roundSnap.hasData ||
                                              roundSnap.data!.docs.isEmpty) {
                                            return const Text('점수: 0 - 0');
                                          }
                                          int homeTotal = 0;
                                          int awayTotal = 0;
                                          for (var doc
                                              in roundSnap.data!.docs) {
                                            final s =
                                                doc.data()
                                                    as Map<String, dynamic>;
                                            final score =
                                                s['score']
                                                    as Map<String, dynamic>?;
                                            if (score != null) {
                                              homeTotal +=
                                                  (score['home'] ?? 0) as int;
                                              awayTotal +=
                                                  (score['away'] ?? 0) as int;
                                            }
                                          }
                                          return Row(
                                            children: [
                                              const Icon(
                                                Icons.emoji_events,
                                                size: 18,
                                                color: Colors.orange,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                '점수: $homeTotal - $awayTotal',
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 16,
                                                ),
                                              ),
                                            ],
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
