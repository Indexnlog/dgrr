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
    final eventRef = FirebaseFirestore.instance
        .collection(collectionName)
        .doc(docId);

    return Scaffold(
      appBar: AppBar(title: const Text('일정 상세')),
      body: StreamBuilder<DocumentSnapshot>(
        stream: eventRef.snapshots(),
        builder: (context, eventSnap) {
          if (eventSnap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!eventSnap.hasData || !eventSnap.data!.exists) {
            return const Center(child: Text('일정을 찾을 수 없습니다.'));
          }

          final eventData = eventSnap.data!.data() as Map<String, dynamic>;
          final dateTs = eventData['date'] as Timestamp?;
          final eventDateStr = dateTs != null ? dateTs.toDate().toString() : '';
          final timeStr =
              '${eventData['startTime'] ?? ''}~${eventData['endTime'] ?? ''}';
          final locationStr = eventData['location']?.toString() ?? '';

          final comments = List<Map<String, dynamic>>.from(
            (eventData['comments'] ?? []) as List,
          );

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 🏷 기본 정보
                Text(
                  '$eventDateStr $timeStr',
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

                // ✅ 참석자 명단 (registrations 컬렉션 기반)
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('registrations')
                      .where('eventId', isEqualTo: docId)
                      .where(
                        'type',
                        isEqualTo: collectionName == 'classes'
                            ? 'class'
                            : 'match',
                      )
                      .where('status', isEqualTo: 'registered')
                      .snapshots(),
                  builder: (context, regSnap) {
                    if (regSnap.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final regs = regSnap.data?.docs ?? [];

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '참석자 (${regs.length})',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (regs.isEmpty)
                          const Text('참석자가 없습니다.')
                        else
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: regs.length,
                            itemBuilder: (context, index) {
                              final reg =
                                  regs[index].data() as Map<String, dynamic>;
                              final userName = reg['userName'] ?? '이름없음';
                              final number = reg['number']?.toString() ?? '';
                              final photoUrl = reg['photoUrl'] ?? '';

                              return ListTile(
                                leading: photoUrl.isNotEmpty
                                    ? CircleAvatar(
                                        backgroundImage: NetworkImage(photoUrl),
                                      )
                                    : const CircleAvatar(
                                        child: Icon(Icons.person),
                                      ),
                                title: Text('$userName (#$number)'),
                              );
                            },
                          ),
                      ],
                    );
                  },
                ),

                const Divider(height: 32),

                // 💬 댓글 / 후기 (기존 classes/matches 문서 내 comments)
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
