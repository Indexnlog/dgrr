import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/match_event_model.dart';
import 'match_detail_page.dart';
import '../manage/team_page.dart'; // ✅ 팀 리스트 페이지 import

class MatchPage extends StatelessWidget {
  const MatchPage({super.key});

  // HEX -> Color 변환
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

  // 네이버 지도 딥링크 열기
  Future<void> _openMap(String location) async {
    final encodedLocation = Uri.encodeComponent(location);
    final naverMapUrl = Uri.parse('nmap://search?query=$encodedLocation');
    final webUrl = Uri.parse(
      'https://map.naver.com/v5/search/$encodedLocation',
    );

    if (await canLaunchUrl(naverMapUrl)) {
      await launchUrl(naverMapUrl, mode: LaunchMode.externalApplication);
    } else if (await canLaunchUrl(webUrl)) {
      await launchUrl(webUrl, mode: LaunchMode.externalApplication);
    } else {
      debugPrint('지도를 열 수 없습니다.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // ✅ AppBar 수정: 팀 리스트 버튼 추가
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
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('matches')
            .where('status', isEqualTo: 'confirmed')
            .orderBy('date', descending: false)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('등록된 매치가 없습니다.'));
          }

          final matches = snapshot.data!.docs.map((doc) {
            return MatchEvent.fromMap(
              doc.data() as Map<String, dynamic>,
              doc.id,
            );
          }).toList();

          return ListView.builder(
            itemCount: matches.length,
            itemBuilder: (context, index) {
              final match = matches[index];
              final now = DateTime.now();
              final matchDate = match.date;
              final dDay = matchDate
                  .difference(DateTime(now.year, now.month, now.day))
                  .inDays;

              // 팀 정보 가져오기
              if (match.teamId == null || match.teamId!.isEmpty) {
                // teamId가 없는 경우 기본 카드로 바로 표시
                return _buildMatchCard(
                  context: context,
                  match: match,
                  dDay: dDay,
                  teamName: match.teamName ?? '상대팀 미지정',
                  teamColor: Colors.grey.shade300,
                  logoUrl: null,
                );
              }

              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection('teams')
                    .doc(match.teamId)
                    .get(),
                builder: (ctx, teamSnap) {
                  if (teamSnap.connectionState == ConnectionState.waiting) {
                    return const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: LinearProgressIndicator(),
                    );
                  }

                  String? logoUrl;
                  String? teamName = match.teamName;
                  Color teamColor = Colors.grey.shade300;

                  if (teamSnap.hasData && teamSnap.data!.exists) {
                    final teamData =
                        teamSnap.data!.data() as Map<String, dynamic>;
                    logoUrl = teamData['logoUrl'];
                    teamName = teamData['name'] ?? teamName;
                    teamColor = _hexToColor(teamData['teamColor']);
                  }

                  return _buildMatchCard(
                    context: context,
                    match: match,
                    dDay: dDay,
                    teamName: teamName ?? '상대팀',
                    teamColor: teamColor,
                    logoUrl: logoUrl,
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  /// 매치 카드 빌드
  Widget _buildMatchCard({
    required BuildContext context,
    required MatchEvent match,
    required int dDay,
    required String teamName,
    required Color teamColor,
    String? logoUrl,
  }) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: teamColor, width: 2),
      ),
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: ListTile(
        leading: (logoUrl != null && logoUrl.isNotEmpty)
            ? CircleAvatar(
                backgroundImage: NetworkImage(logoUrl),
                backgroundColor: teamColor.withOpacity(0.2),
              )
            : CircleAvatar(
                backgroundColor: teamColor,
                child: const Icon(Icons.sports_soccer, color: Colors.white),
              ),
        title: InkWell(
          onTap: () {
            if (match.location != null && match.location!.isNotEmpty) {
              _openMap(match.location!);
            }
          },
          child: Text(
            '${match.time ?? ''} @ ${match.location ?? ''}',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              decoration: TextDecoration.underline,
            ),
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('상대팀: $teamName'),
            Text('점수: ${match.score.home} - ${match.score.away}'),
            Text(
              dDay == 0
                  ? 'D-Day'
                  : dDay > 0
                  ? 'D-$dDay'
                  : 'D+${-dDay}',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: dDay == 0
                    ? Colors.red
                    : (dDay > 0 && dDay <= 3)
                    ? Colors.orange
                    : Colors.grey,
              ),
            ),
          ],
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => MatchDetailPage(event: match),
            ),
          );
        },
      ),
    );
  }
}
