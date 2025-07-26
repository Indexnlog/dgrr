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

          // attendees, comments 안전한 변환
          final attendees = List<Map<String, dynamic>>.from(
            (data['attendees'] ?? []) as List,
          );
          final comments = List<Map<String, dynamic>>.from(
            (data['comments'] ?? []) as List,
          );

          // date와 time도 null-safe 처리
          final dateStr = data['date']?.toString() ?? '';
          final timeStr = data['time']?.toString() ?? '';
          final locationStr = data['location']?.toString() ?? '';

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 🏷 기본 정보
                Text(
                  '$dateStr $timeStr',
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
                    Expanded(child: Text(locationStr)),
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
                      final status = a['status']?.toString() ?? '';
                      final userId = a['userId']?.toString() ?? '알 수 없음';
                      final reason = a['reason']?.toString();

                      return ListTile(
                        leading: Icon(
                          status == 'attending'
                              ? Icons.check_circle
                              : Icons.cancel,
                          color: status == 'attending'
                              ? Colors.green
                              : Colors.red,
                        ),
                        title: Text(userId),
                        subtitle: (reason != null && reason.isNotEmpty)
                            ? Text('사유: $reason')
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
                      final text = c['text']?.toString() ?? '';
                      final userId = c['userId']?.toString() ?? '';
                      return ListTile(
                        leading: const Icon(Icons.comment, color: Colors.blue),
                        title: Text(text),
                        subtitle: Text(userId),
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
