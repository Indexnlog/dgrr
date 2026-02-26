import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/event.dart';
import '../models/event_model.dart';

/// 수업/이벤트 Firestore 데이터소스
class EventRemoteDataSource {
  EventRemoteDataSource({required this.firestore});

  final FirebaseFirestore firestore;

  CollectionReference<Map<String, dynamic>> _eventsRef(String teamId) =>
      firestore.collection('teams').doc(teamId).collection('events');

  /// 다가오는 수업 목록 (오늘 이후, type == class)
  Stream<List<EventModel>> watchUpcomingClasses(String teamId) {
    final today = DateTime.now();
    final todayStr =
        '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

    return _eventsRef(teamId)
        .where('type', isEqualTo: 'class')
        .where('date', isGreaterThanOrEqualTo: todayStr)
        .orderBy('date')
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => EventModel.fromFirestore(doc.id, doc.data()))
            .toList());
  }

  /// 기간별 수업 목록 (캘린더 월 표시용)
  Stream<List<EventModel>> watchClassesInRange(
    String teamId,
    String startDate,
    String endDate,
  ) {
    return _eventsRef(teamId)
        .where('type', isEqualTo: 'class')
        .where('date', isGreaterThanOrEqualTo: startDate)
        .where('date', isLessThanOrEqualTo: endDate)
        .orderBy('date')
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => EventModel.fromFirestore(doc.id, doc.data()))
            .toList());
  }

  /// 수업 생성
  Future<String> createClass(String teamId, EventModel event) async {
    final doc = await _eventsRef(teamId).add(event.toFirestore());
    return doc.id;
  }

  /// 수업 여러 건 일괄 생성 (투표 결과로부터)
  /// 반환: 첫 번째 생성된 이벤트 ID (linkedEventId 저장용)
  Future<String?> createClassesBatch(
    String teamId,
    List<EventModel> events,
  ) async {
    if (events.isEmpty) return null;
    final batch = firestore.batch();
    DocumentReference? firstRef;
    for (final event in events) {
      final ref = _eventsRef(teamId).doc();
      firstRef ??= ref;
      batch.set(ref, event.toFirestore());
    }
    await batch.commit();
    return firstRef?.id;
  }

  /// 참석 상태 변경 (트랜잭션)
  Future<void> updateAttendeeStatus({
    required String teamId,
    required String eventId,
    required String userId,
    required String userName,
    required int? number,
    required AttendeeStatus status,
    String? reason,
  }) async {
    final ref = _eventsRef(teamId).doc(eventId);

    await firestore.runTransaction((tx) async {
      final snap = await tx.get(ref);
      if (!snap.exists) throw Exception('수업 문서가 존재하지 않습니다');
      final data = snap.data()!;

      final attendees =
          (data['attendees'] as List?)?.map((e) => e as Map<String, dynamic>).toList() ?? [];

      // 기존 참석 정보 제거
      attendees.removeWhere((a) => a['userId'] == userId);

      // 새 참석 정보 추가
      attendees.add({
        'userId': userId,
        'userName': userName,
        if (number != null) 'number': number,
        'status': status.value,
        if (reason != null) 'reason': reason,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // 출석 요약 재계산
      int present = 0;
      int absent = 0;
      for (final a in attendees) {
        final s = a['status'] as String?;
        if (s == 'attending' || s == 'late') {
          present++;
        } else if (s == 'absent') {
          absent++;
        }
      }

      tx.update(ref, {
        'attendees': attendees,
        'attendance': {'present': present, 'absent': absent},
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  /// 수업 종료 (출석 확정)
  Future<void> finishClass(String teamId, String eventId) async {
    await _eventsRef(teamId).doc(eventId).update({
      'status': 'finished',
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// 단일 수업 실시간 스트림
  Stream<EventModel?> watchClass(String teamId, String eventId) {
    return _eventsRef(teamId).doc(eventId).snapshots().map((snap) {
      if (!snap.exists || snap.data() == null) return null;
      return EventModel.fromFirestore(snap.id, snap.data()!);
    });
  }
}
