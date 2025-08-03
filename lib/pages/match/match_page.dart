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

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final todayStart = DateTime(today.year, today.month, today.day); // 🔥 기준

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
          final myTeamId = udata['teamId'] ?? '';

          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('teams')
                .doc(myTeamId)
                .collection('matches')
                .where('recruitStatus', isEqualTo: 'confirmed')
                .where(
                  'date',
                  isGreaterThanOrEqualTo: Timestamp.fromDate(todayStart),
                ) // ✅ 오늘 이후만
                .orderBy('date')
                .snapshots(),
            builder: (context, snap) {
              if (!snap.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final docs = snap.data!.docs;
              if (docs.isEmpty) {
                return const Center(child: Text('예정된 매치가 없습니다.'));
              }

              final matches = docs.map((doc) {
                return MatchEvent.fromMap(
                  doc.data() as Map<String, dynamic>,
                  doc.id,
                );
              }).toList();

              // ✅ 기존 ListView 렌더링 로직 유지
              return ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: matches.length,
                itemBuilder: (context, index) {
                  final match = matches[index];
                  final dDay = match.date.difference(DateTime.now()).inDays;

                  // 아래는 그대로 유지
                  // ...
                  return FutureBuilder<DocumentSnapshot>(
                    future: FirebaseFirestore.instance
                        .collection('teams')
                        .doc(match.teamId)
                        .get(),
                    builder: (ctx, teamSnap) {
                      // 🔁 팀 색상/로고 처리
                      // 🔁 카드 UI + InkWell + 상세 이동
                      // 🔁 지도 열기
                      // 🔁 경기 상태 계산
                      // 🔁 라운드별 점수 계산
                      // 그대로 두면 됨
                      // ...
                      return /* 생략 */;
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
