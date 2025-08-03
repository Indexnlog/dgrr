import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:yourapp/pages/polls/poll_model.dart'; // ✅ 실제 경로에 맞게 수정 필요

class PollService {
  static final _firestore = FirebaseFirestore.instance;
  static final _pollsRef = _firestore.collection('polls');

  /// ✅ 투표 생성
  static Future<void> createPoll(PollModel poll) async {
    await _pollsRef.doc(poll.id).set(poll.toMap());
  }

  /// ✅ 투표 참여
  static Future<void> voteOnPoll({
    required String pollId,
    required String optionId,
    required String userId,
  }) async {
    final pollDoc = await _pollsRef.doc(pollId).get();
    if (!pollDoc.exists) return;

    final data = pollDoc.data() as Map<String, dynamic>;
    final options = List<Map<String, dynamic>>.from(data['options'] ?? []);

    for (var option in options) {
      final votes = List<String>.from(option['votes'] ?? []);
      // 본인 기존 투표 제거
      votes.remove(userId);
      if (option['id'] == optionId) {
        votes.add(userId);
      }
      option['votes'] = votes;
      option['voteCount'] = votes.length;
    }

    await _pollsRef.doc(pollId).update({'options': options});
  }

  /// ✅ 투표 마감
  static Future<void> closePoll(String pollId) async {
    await _pollsRef.doc(pollId).update({
      'isActive': false,
      'resultFinalizedAt': Timestamp.now(),
    });
  }
}
