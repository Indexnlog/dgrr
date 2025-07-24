import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ScheduleDetailPage extends StatelessWidget {
  final String collectionName; // 'classes' or 'matches'
  final String docId;

  const ScheduleDetailPage({
    super.key,
    required this.collectionName,
    required this.docId,
  });

  @override
  Widget build(BuildContext context) {
    final docRef = FirebaseFirestore.instance
        .collection(collectionName)
        .doc(docId);

    return Scaffold(
      appBar: AppBar(title: const Text('일정 상세')),
      body: StreamBuilder<DocumentSnapshot>(
        stream: docRef.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('일정을 찾을 수 없습니다.'));
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;
          final attendees = List<Map<String, dynamic>>.from(
            data['attendees'] ?? [],
          );
          final comments = List<Map<String, dynamic>>.from(
            data['comments'] ?? [],
          );

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 🏷 기본 정보
                Text(
                  '${data['date']} ${data['time']}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.place, color: Colors.red),
                    const SizedBox(width: 8),
                    Expanded(child: Text(data['location'] ?? '')),
                  ],
                ),
                const SizedBox(height: 24),

                // ✅ 참석자 명단
                Text(
                  '참석자 (${attendees.length})',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                if (attendees.isEmpty)
                  const Text('참석자가 없습니다.')
                else
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: attendees.length,
                    itemBuilder: (context, index) {
                      final a = attendees[index];
                      return ListTile(
                        leading: Icon(
                          a['status'] == 'attending'
                              ? Icons.check_circle
                              : Icons.cancel,
                          color: a['status'] == 'attending'
                              ? Colors.green
                              : Colors.red,
                        ),
                        title: Text(a['userId'] ?? '알 수 없음'),
                        subtitle: a['reason'] != null && a['reason']!.isNotEmpty
                            ? Text('사유: ${a['reason']}')
                            : null,
                      );
                    },
                  ),
                const Divider(height: 32),

                // 💬 댓글 / 후기
                Text(
                  '후기 (${comments.length})',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                if (comments.isEmpty)
                  const Text('아직 후기가 없습니다.')
                else
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: comments.length,
                    itemBuilder: (context, index) {
                      final c = comments[index];
                      return ListTile(
                        leading: const Icon(Icons.comment, color: Colors.blue),
                        title: Text(c['text'] ?? ''),
                        subtitle: Text(c['userId'] ?? ''),
                      );
                    },
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
