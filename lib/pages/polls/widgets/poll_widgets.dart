import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../poll_model.dart';

class PollWidget extends StatelessWidget {
  final PollModel poll;
  final String userId;
  final bool isEditable; // 작성자면 마감 버튼 등 노출

  const PollWidget({
    super.key,
    required this.poll,
    required this.userId,
    this.isEditable = false,
  });

  bool get hasVoted {
    return poll.options.any((o) => o.votes.contains(userId));
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              poll.title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ...poll.options.map((opt) {
              final isSelected = opt.votes.contains(userId);
              final totalVotes = poll.options.fold<int>(
                0,
                (sum, o) => sum + o.voteCount,
              );
              final percent = totalVotes == 0
                  ? 0.0
                  : opt.voteCount / totalVotes;

              return Column(
                children: [
                  GestureDetector(
                    onTap: poll.isActive && !hasVoted
                        ? () {
                            // TODO: 투표 처리 로직 연결 (poll_service.dart)
                          }
                        : null,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 10,
                        horizontal: 12,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: isSelected
                              ? Colors.blue
                              : Colors.grey.shade300,
                        ),
                        borderRadius: BorderRadius.circular(8),
                        color: isSelected
                            ? Colors.blue.withOpacity(0.1)
                            : Colors.white,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(opt.text ?? opt.date.toString()),
                          ),
                          if (!poll.isActive || hasVoted)
                            Text('${opt.voteCount}표'),
                        ],
                      ),
                    ),
                  ),
                  if (!poll.isActive || hasVoted)
                    LinearProgressIndicator(
                      value: percent,
                      minHeight: 6,
                      backgroundColor: Colors.grey.shade200,
                      color: Colors.blue,
                    ),
                  const SizedBox(height: 12),
                ],
              );
            }).toList(),
            if (poll.isActive && isEditable)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () {
                    // TODO: 마감 처리 연결
                  },
                  icon: const Icon(Icons.lock),
                  label: const Text('투표 마감'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
