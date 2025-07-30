import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HomeTab extends StatelessWidget {
  const HomeTab({super.key});

  /// ✅ 현재 로그인된 사용자의 teamId를 찾아 해당 team의 members 컬렉션에서 사용자 정보 반환
  Future<Map<String, dynamic>?> _fetchUserData() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return null;

    // 모든 팀 조회
    final teamQuery = await FirebaseFirestore.instance
        .collection('teams')
        .get();

    for (var teamDoc in teamQuery.docs) {
      final teamId = teamDoc.id;

      final memberDoc = await FirebaseFirestore.instance
          .collection('teams')
          .doc(teamId)
          .collection('members')
          .doc(uid)
          .get();

      if (memberDoc.exists) {
        final data = memberDoc.data();
        data?['teamId'] = teamId; // teamId도 포함해서 리턴
        return data;
      }
    }

    return null; // 사용자를 포함한 팀이 없음
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>?>(
      future: _fetchUserData(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data == null) {
          return const Center(child: Text('사용자 정보를 불러올 수 없습니다.'));
        }

        final userData = snapshot.data!;
        final name = userData['name'] ?? '이름 없음';
        final number = userData['number'] ?? '';
        final team = userData['teamName'] ?? '소속 없음';
        final photoUrl = userData['photoUrl'] ?? '';
        final teamId = userData['teamId'];

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundImage: photoUrl.isNotEmpty
                      ? NetworkImage(photoUrl)
                      : null,
                  radius: 32,
                  child: photoUrl.isEmpty
                      ? const Icon(Icons.person, size: 32)
                      : null,
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$name (#$number)',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text('팀: $team'),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Text(
              '📢 최근 공지사항',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _buildNoticeList(teamId),
          ],
        );
      },
    );
  }

  /// ✅ 팀 ID 기반 공지사항 조회
  Widget _buildNoticeList(String teamId) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('teams')
          .doc(teamId)
          .collection('notices')
          .orderBy('createdAt', descending: true)
          .limit(3)
          .snapshots(),
      builder: (context, snap) {
        if (!snap.hasData || snap.data!.docs.isEmpty) {
          return const Text('공지사항이 없습니다.');
        }

        return Column(
          children: snap.data!.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final title = data['title'] ?? '제목 없음';
            final content = data['content'] ?? '';
            final createdAt = (data['createdAt'] as Timestamp?)?.toDate();

            return Card(
              margin: const EdgeInsets.symmetric(vertical: 6),
              child: ListTile(
                title: Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  content.length > 50
                      ? '${content.substring(0, 50)}...'
                      : content,
                ),
                trailing: createdAt != null
                    ? Text(
                        '${createdAt.month}/${createdAt.day}',
                        style: const TextStyle(fontSize: 12),
                      )
                    : null,
              ),
            );
          }).toList(),
        );
      },
    );
  }
}
