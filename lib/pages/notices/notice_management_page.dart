import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class NoticeManagementPage extends StatelessWidget {
  const NoticeManagementPage({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      appBar: AppBar(title: const Text('📋 공지 관리')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('posts')
            .where('category', isEqualTo: '공지')
            .where('authorId', isEqualTo: currentUid) // 내가 작성한 공지만 보기
            .orderBy('createdAt', descending: true)
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

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: ListTile(
                  title: Row(
                    children: [
                      if (isPinned)
                        const Icon(
                          Icons.push_pin,
                          color: Colors.orange,
                          size: 18,
                        ),
                      if (isPinned) const SizedBox(width: 4),
                      Expanded(child: Text(title)),
                    ],
                  ),
                  subtitle: Text(
                    content,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () {
                          // TODO: 수정 페이지로 이동
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('✏️ 수정 기능은 추후 구현 예정')),
                          );
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('공지 삭제'),
                              content: Text('“$title” 공지를 삭제하시겠습니까?'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx, false),
                                  child: const Text('취소'),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx, true),
                                  child: const Text(
                                    '삭제',
                                    style: TextStyle(color: Colors.red),
                                  ),
                                ),
                              ],
                            ),
                          );

                          if (confirm == true) {
                            await FirebaseFirestore.instance
                                .collection('posts')
                                .doc(doc.id)
                                .delete();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('🗑️ 공지를 삭제했습니다.')),
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
