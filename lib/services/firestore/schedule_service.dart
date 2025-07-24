import 'package:cloud_firestore/cloud_firestore.dart';

class ScheduleService {
  /// ✅ 수업 일정 스트림
  static Stream<QuerySnapshot> getClassesStream() {
    return FirebaseFirestore.instance
        .collection('classes')
        .orderBy('date')
        .snapshots();
  }

  /// ✅ 매치 일정 스트림
  static Stream<QuerySnapshot> getMatchesStream() {
    return FirebaseFirestore.instance
        .collection('matches')
        .orderBy('date')
        .snapshots();
  }

  /// ✅ 참석/불참 업데이트 (수업/매치 공통)
  static Future<void> updateAttendance({
    required String collectionName, // 'classes' or 'matches'
    required String docId,
    required String userId,
    required String status, // 'attending' or 'absent'
    String? reason,
  }) async {
    final docRef = FirebaseFirestore.instance
        .collection(collectionName)
        .doc(docId);

    await FirebaseFirestore.instance.runTransaction((transaction) async {
      final snapshot = await transaction.get(docRef);
      if (!snapshot.exists) return;

      final data = snapshot.data() as Map<String, dynamic>;
      List attendees = List.from(data['attendees'] ?? []);

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
}
