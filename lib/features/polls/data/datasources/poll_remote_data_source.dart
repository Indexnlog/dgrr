import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/poll_model.dart';

/// 투표 Firestore 데이터소스
class PollRemoteDataSource {
  PollRemoteDataSource({required this.firestore});

  final FirebaseFirestore firestore;

  CollectionReference<Map<String, dynamic>> _pollsRef(String teamId) =>
      firestore.collection('teams').doc(teamId).collection('polls');

  /// 활성 투표 목록 실시간 스트림
  Stream<List<PollModel>> watchActivePolls(String teamId) {
    return _pollsRef(teamId)
        .where('isActive', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => PollModel.fromFirestore(doc.id, doc.data()))
            .toList());
  }

  /// 모든 투표 (최근순, 페이지네이션 limit 기본 30)
  Stream<List<PollModel>> watchAllPolls(String teamId, {int limit = 30}) {
    return _pollsRef(teamId)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => PollModel.fromFirestore(doc.id, doc.data()))
            .toList());
  }

  /// 특정 월의 월별 등록 투표 조회 (category=membership, targetMonth)
  Stream<PollModel?> watchMembershipPollForMonth(
    String teamId,
    String targetMonth,
  ) {
    return _pollsRef(teamId)
        .where('category', isEqualTo: 'membership')
        .where('targetMonth', isEqualTo: targetMonth)
        .limit(1)
        .snapshots()
        .map((snap) {
          if (snap.docs.isEmpty) return null;
          return PollModel.fromFirestore(
            snap.docs.first.id,
            snap.docs.first.data(),
          );
        });
  }

  /// 단일 투표 실시간 스트림
  Stream<PollModel?> watchPoll(String teamId, String pollId) {
    return _pollsRef(teamId).doc(pollId).snapshots().map((snap) {
      if (!snap.exists || snap.data() == null) return null;
      return PollModel.fromFirestore(snap.id, snap.data()!);
    });
  }

  /// 투표 생성
  Future<String> createPoll(String teamId, PollModel poll) async {
    final doc = await _pollsRef(teamId).add(poll.toFirestore());
    return doc.id;
  }

  /// 투표하기 (트랜잭션: option의 votes 배열에 uid 추가 + voteCount 증가)
  Future<void> vote(
    String teamId,
    String pollId,
    String optionId,
    String uid,
  ) async {
    final ref = _pollsRef(teamId).doc(pollId);

    await firestore.runTransaction((tx) async {
      final snap = await tx.get(ref);
      if (!snap.exists) throw Exception('투표가 존재하지 않습니다');
      final data = snap.data()!;

      final options = (data['options'] as List?)
              ?.map((e) => Map<String, dynamic>.from(e as Map))
              .toList() ??
          [];

      for (final option in options) {
        final votes = List<String>.from(option['votes'] ?? []);
        if (option['id'] == optionId) {
          if (!votes.contains(uid)) {
            votes.add(uid);
          }
        }
        option['votes'] = votes;
        option['voteCount'] = votes.length;
      }

      tx.update(ref, {
        'options': options,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  /// 투표 취소 (트랜잭션: option의 votes 배열에서 uid 제거)
  Future<void> unvote(
    String teamId,
    String pollId,
    String optionId,
    String uid,
  ) async {
    final ref = _pollsRef(teamId).doc(pollId);

    await firestore.runTransaction((tx) async {
      final snap = await tx.get(ref);
      if (!snap.exists) throw Exception('투표가 존재하지 않습니다');
      final data = snap.data()!;

      final options = (data['options'] as List?)
              ?.map((e) => Map<String, dynamic>.from(e as Map))
              .toList() ??
          [];

      for (final option in options) {
        final votes = List<String>.from(option['votes'] ?? []);
        if (option['id'] == optionId) {
          votes.remove(uid);
        }
        option['votes'] = votes;
        option['voteCount'] = votes.length;
      }

      tx.update(ref, {
        'options': options,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  /// 투표 종료
  Future<void> closePoll(String teamId, String pollId) async {
    await _pollsRef(teamId).doc(pollId).update({
      'isActive': false,
      'resultFinalizedAt': FieldValue.serverTimestamp(),
    });
  }

  /// 투표에 연결된 이벤트 ID 설정 (출석 투표 → 수업 생성 후)
  Future<void> setLinkedEventId(
    String teamId,
    String pollId,
    String eventId,
  ) async {
    await _pollsRef(teamId).doc(pollId).update({
      'linkedEventId': eventId,
    });
  }
}
