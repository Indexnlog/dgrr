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

  /// ✅ 최초 일정 자동 생성 (3개월치)
  static Future<void> generateInitialSchedules({required String teamId}) async {
    final now = DateTime.now();
    final end = DateTime(now.year, now.month + 3, 0);
    final firestore = FirebaseFirestore.instance;

    for (
      DateTime date = now;
      date.isBefore(end);
      date = date.add(const Duration(days: 1))
    ) {
      final weekday = date.weekday;

      // 📘 매주 목요일: 수업
      if (weekday == DateTime.thursday) {
        await firestore.collection('classes').add({
          'teamId': teamId,
          'date': Timestamp.fromDate(date),
          'startTime': '20:00',
          'endTime': '22:00',
          'status': 'draft',
          'type': 'regular',
          'createdAt': Timestamp.now(),
        });
      }

      // ⚽ 둘째, 넷째 일요일: 매치
      if (weekday == DateTime.sunday) {
        final weekOfMonth = ((date.day - 1) ~/ 7) + 1;
        if (weekOfMonth == 2 || weekOfMonth == 4) {
          await firestore.collection('matches').add({
            'teamId': teamId,
            'date': Timestamp.fromDate(date),
            'startTime': '20:00',
            'endTime': '22:00',
            'status': 'draft',
            'type': 'regular',
            'createdAt': Timestamp.now(),
          });
        }
      }
    }
  }

  /// ✅ 매달 1일: 다음 1개월 일정만 생성
  static Future<void> generateMonthlySchedule({required String teamId}) async {
    final now = DateTime.now();
    final targetMonth = DateTime(now.year, now.month + 3, 1);
    final targetEnd = DateTime(targetMonth.year, targetMonth.month + 1, 0);
    final firestore = FirebaseFirestore.instance;

    for (
      DateTime date = targetMonth;
      date.isBefore(targetEnd);
      date = date.add(const Duration(days: 1))
    ) {
      final weekday = date.weekday;

      // 📘 매주 목요일: 수업
      if (weekday == DateTime.thursday) {
        await firestore.collection('classes').add({
          'teamId': teamId,
          'date': Timestamp.fromDate(date),
          'startTime': '20:00',
          'endTime': '22:00',
          'status': 'draft',
          'type': 'regular',
          'createdAt': Timestamp.now(),
        });
      }

      // ⚽ 둘째, 넷째 일요일: 매치
      if (weekday == DateTime.sunday) {
        final weekOfMonth = ((date.day - 1) ~/ 7) + 1;
        if (weekOfMonth == 2 || weekOfMonth == 4) {
          await firestore.collection('matches').add({
            'teamId': teamId,
            'date': Timestamp.fromDate(date),
            'startTime': '20:00',
            'endTime': '22:00',
            'status': 'draft',
            'type': 'regular',
            'createdAt': Timestamp.now(),
          });
        }
      }
    }
  }

  /// ✅ 다음달 draft 일정 일괄 확정 처리
  static Future<void> confirmNextMonthSchedules({
    required String teamId,
  }) async {
    final firestore = FirebaseFirestore.instance;
    final now = DateTime.now();
    final nextMonthStart = DateTime(now.year, now.month + 1, 1);
    final nextMonthEnd = DateTime(now.year, now.month + 2, 0);

    for (final collection in ['classes', 'matches']) {
      final query = await firestore
          .collection(collection)
          .where('teamId', isEqualTo: teamId)
          .where('status', isEqualTo: 'draft')
          .where(
            'date',
            isGreaterThanOrEqualTo: Timestamp.fromDate(nextMonthStart),
          )
          .where('date', isLessThanOrEqualTo: Timestamp.fromDate(nextMonthEnd))
          .get();

      for (final doc in query.docs) {
        await doc.reference.update({'status': 'regular'});
      }
    }
  }
}
