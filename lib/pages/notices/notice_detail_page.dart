import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class NoticeDetailPage extends StatelessWidget {
  final String teamId;
  final String noticeId;
  const NoticeDetailPage({
    super.key,
    required this.teamId,
    required this.noticeId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('📢 공지 상세')),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance
            .collection('teams')
            .doc(teamId)
            .collection('notices')
            .doc(noticeId)
            .get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('❌ 해당 공지를 찾을 수 없습니다.'));
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;
          final title = data['title'] ?? '제목 없음';
          final content = data['content'] ?? '';
          final isPinned = data['isPinned'] ?? false;
          final createdAt = (data['createdAt'] as Timestamp?)?.toDate();
          final publishAt = (data['publishAt'] as Timestamp?)?.toDate();

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 🔹 제목
                Row(
                  children: [
                    if (isPinned)
                      const Icon(Icons.push_pin, color: Colors.orange),
                    if (isPinned) const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        title,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // 🕒 날짜 정보
                if (publishAt != null)
                  Text(
                    '게시 예정: ${publishAt.toLocal()}',
                    style: const TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                if (createdAt != null)
                  Text(
                    '작성일: ${createdAt.toLocal()}',
                    style: const TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                const Divider(height: 32),

                // 📄 내용
                Text(content, style: const TextStyle(fontSize: 16)),
              ],
            ),
          );
        },
      ),
    );
  }
}
