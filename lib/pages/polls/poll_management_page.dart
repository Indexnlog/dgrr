import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../poll_model.dart';
import '../../../services/firestore/poll_service.dart';

class PollManagementPage extends StatelessWidget {
  final String userId;

  const PollManagementPage({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    final pollRef = FirebaseFirestore.instance
        .collection('polls')
        .where('createdBy', isEqualTo: userId)
        .orderBy('createdAt', descending: true);

    return Scaffold(
      appBar: AppBar(title: const Text('🗳 내가 만든 투표 관리')),
      body: StreamBuilder<QuerySnapshot>(
        stream: pollRef.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('내가 만든 투표가 없습니다.'));
          }

          final polls = snapshot.data!.docs
              .map((doc) => PollModel.fromDoc(doc))
              .toList();

          return ListView.builder(
            itemCount: polls.length,
            itemBuilder: (context, index) {
              final poll = polls[index];
              final totalVotes = poll.options.fold<int>(
                0,
                (sum, o) => sum + o.voteCount,
              );

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  title: Text(
                    poll.title,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text('총 참여자 수: $totalVotes명'),
                      if (!poll.isActive)
                        const Text(
                          '✅ 마감됨',
                          style: TextStyle(color: Colors.grey),
                        ),
                    ],
                  ),
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) async {
                      if (value == 'close') {
                        await PollService.closePoll(poll.id);
                      } else if (value == 'delete') {
                        await FirebaseFirestore.instance
                            .collection('polls')
                            .doc(poll.id)
                            .delete();
                      }
                    },
                    itemBuilder: (context) => [
                      if (poll.isActive)
                        const PopupMenuItem(
                          value: 'close',
                          child: Text('마감하기'),
                        ),
                      const PopupMenuItem(value: 'delete', child: Text('삭제하기')),
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
