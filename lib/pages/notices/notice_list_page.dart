import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'notice_detail_page.dart';

class NoticeListPage extends StatelessWidget {
  const NoticeListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('📋 전체 공지')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('posts')
            .where('category', isEqualTo: '공지')
            .orderBy('publishAt', descending: true) // 최신순
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('등록된 공지가 없습니다.'));
          }

          final docs = snapshot.data!.docs;

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>;

              final title = data['title'] ?? '제목 없음';
              final content = data['content'] ?? '';
              final isPinned = data['isPinned'] ?? false;
              final publishAt = (data['publishAt'] as Timestamp?)?.toDate();

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: ListTile(
                  leading: isPinned
                      ? const Icon(Icons.push_pin, color: Colors.orange)
                      : const Icon(Icons.campaign, color: Colors.blueGrey),
                  title: Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        content,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (publishAt != null)
                        Text(
                          '게시일: ${publishAt.toLocal()}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                    ],
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => NoticeDetailPage(postId: doc.id),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
