import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart'; // 날짜 포맷용

class HomeTab extends StatelessWidget {
  const HomeTab({super.key});

  Future<Map<String, dynamic>?> _fetchUserData() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return null;

    final snapshot = await FirebaseFirestore.instance
        .collection('members')
        .doc(uid)
        .get();

    final data = snapshot.data();
    if (data == null || data is! Map<String, dynamic>) return null;
    return data;
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
        final name = (userData['name'] ?? '이름 없음').toString();
        final number = userData['number']?.toString() ?? '';
        final team = (userData['teamName'] ?? '소속 없음').toString();
        final photoUrl = (userData['photoUrl'] ?? '').toString();

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
                      number.isNotEmpty ? '$name (#$number)' : name,
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
            _buildNoticeList(),
          ],
        );
      },
    );
  }

  Widget _buildNoticeList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
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
            final data = doc.data();
            if (data is! Map<String, dynamic>) return const SizedBox.shrink();

            final title = data['title'] ?? '제목 없음';
            final content = data['content'] ?? '';
            final createdAt = (data['createdAt'] as Timestamp?)?.toDate();

            return Card(
              margin: const EdgeInsets.symmetric(vertical: 6),
              child: ListTile(
                title: Text(
                  title.toString(),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  content.toString().length > 50
                      ? '${content.toString().substring(0, 50)}...'
                      : content.toString(),
                ),
                trailing: createdAt != null
                    ? Text(
                        DateFormat('MM/dd').format(createdAt),
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
