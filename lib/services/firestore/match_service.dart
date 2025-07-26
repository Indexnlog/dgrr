import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/match_event_model.dart';

class MatchService {
  /// ✅ matches 컬렉션 실시간 구독 (status 필터링 가능)
  static Stream<List<MatchEvent>> getMatches({String? status}) {
    Query query = FirebaseFirestore.instance.collection('matches');

    // status로 필터링하고 싶으면 이렇게
    if (status != null) {
      query = query.where('status', isEqualTo: status);
    }

    return query.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return MatchEvent.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
    });
  }

  /// ✅ 매치 단일 문서 스트림 (상세 페이지에서 사용)
  static Stream<MatchEvent?> getMatchDetail(String matchId) {
    return FirebaseFirestore.instance
        .collection('matches')
        .doc(matchId)
        .snapshots()
        .map((doc) {
          if (!doc.exists) return null;
          return MatchEvent.fromMap(doc.data() as Map<String, dynamic>, doc.id);
        });
  }

  /// ✅ 참석/불참 업데이트
  static Future<void> updateAttendance({
    required String matchId,
    required String userId,
    required String status, // 'attending' or 'absent'
    String? reason,
  }) async {
    final docRef = FirebaseFirestore.instance
        .collection('matches')
        .doc(matchId);

    await FirebaseFirestore.instance.runTransaction((transaction) async {
      final snapshot = await transaction.get(docRef);
      if (!snapshot.exists) return;

      final data = snapshot.data() as Map<String, dynamic>;
      List attendees = List.from(data['attendees'] ?? []);

      // 기존 참석자 찾기
      final idx = attendees.indexWhere((a) => a['userId'] == userId);
      final newData = {
        'userId': userId,
        'status': status,
        'reason': reason ?? '',
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (idx >= 0) {
        attendees[idx] = newData;
      } else {
        attendees.add(newData);
      }

      transaction.update(docRef, {'attendees': attendees});
    });
  }

  /// ✅ 새로운 비정기 매치 등록
  static Future<void> addIrregularMatch(MatchEvent match) async {
    await FirebaseFirestore.instance.collection('matches').add(match.toMap());
  }

  /// ✅ 기존 매치 수정 (예: 상대팀 확정)
  static Future<void> updateMatch(
    String matchId,
    Map<String, dynamic> data,
  ) async {
    await FirebaseFirestore.instance
        .collection('matches')
        .doc(matchId)
        .update(data);
  }
}
