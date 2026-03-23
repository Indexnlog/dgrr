import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/reservation_notice_model.dart';

/// 예약 공지 Firestore 데이터소스
class ReservationNoticeRemoteDataSource {
  ReservationNoticeRemoteDataSource({required this.firestore});

  final FirebaseFirestore firestore;

  CollectionReference<Map<String, dynamic>> _noticesRef(String teamId) =>
      firestore.collection('teams').doc(teamId).collection('reservation_notices');

  CollectionReference<Map<String, dynamic>> _notificationsRef(String teamId) =>
      firestore.collection('teams').doc(teamId).collection('notifications');

  CollectionReference<Map<String, dynamic>> _membersRef(String teamId) =>
      firestore.collection('teams').doc(teamId).collection('members');

  /// 예약 공지 목록 (다가오는 것부터)
  Stream<List<ReservationNoticeModel>> watchUpcomingNotices(String teamId) {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);

    return _noticesRef(teamId)
        .where('targetDate', isGreaterThanOrEqualTo: Timestamp.fromDate(todayStart))
        .orderBy('targetDate')
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) =>
                ReservationNoticeModel.fromFirestore(doc.id, doc.data()))
            .toList());
  }

  /// 예약 공지 단건 조회
  Stream<ReservationNoticeModel?> watchNotice(
    String teamId,
    String noticeId,
  ) {
    return _noticesRef(teamId)
        .doc(noticeId)
        .snapshots()
        .map((snap) => snap.exists
            ? ReservationNoticeModel.fromFirestore(snap.id, snap.data()!)
            : null);
  }

  /// 예약 공지 생성
  Future<String> createNotice(
    String teamId,
    ReservationNoticeModel notice,
  ) async {
    final doc = await _noticesRef(teamId).add(notice.toFirestore());
    return doc.id;
  }

  /// 예약 공지 발송 (status → published)
  Future<void> publishNotice(String teamId, String noticeId) async {
    await _noticesRef(teamId).doc(noticeId).update({
      'status': 'published',
      'publishedAt': FieldValue.serverTimestamp(),
    });
  }

  /// 예약 성공 보고 (트랜잭션) + 전체 멤버 알림 생성
  Future<void> reportSuccess({
    required String teamId,
    required String noticeId,
    required String groundId,
    required String userId,
    required String userName,
  }) async {
    final noticeRef = _noticesRef(teamId).doc(noticeId);

    await firestore.runTransaction((tx) async {
      final noticeSnap = await tx.get(noticeRef);
      if (!noticeSnap.exists) throw Exception('예약 공지가 존재하지 않습니다');

      final data = noticeSnap.data()!;
      final slots = (data['slots'] as List?)
              ?.map((e) => Map<String, dynamic>.from(e as Map))
              .toList() ??
          [];

      final slotIndex = slots.indexWhere((s) => s['groundId'] == groundId);
      if (slotIndex < 0) throw Exception('해당 구장을 찾을 수 없습니다');

      final slot = slots[slotIndex];
      if (slot['result'] == 'success') {
        throw Exception('이미 예약 성공 처리되었습니다');
      }

      if (slot['managers'] == null ||
          !(slot['managers'] as List).contains(userId)) {
        throw Exception('해당 구장 담당자가 아닙니다');
      }

      slot['result'] = 'success';
      slot['successBy'] = userId;
      slot['successAt'] = FieldValue.serverTimestamp();

      final allReported = slots.every((s) =>
          s['result'] == 'success' || s['result'] == 'failed');
      tx.update(noticeRef, {
        'slots': slots,
        if (allReported) 'status': 'completed',
      });
    });

    // 전체 멤버에게 알림 생성 (트랜잭션 외부 - Transaction.get은 Query 미지원)
    final membersSnap = await _membersRef(teamId)
        .where('status', isEqualTo: 'active')
        .get();
    final memberIds = membersSnap.docs.map((d) => d.id).toList();
    if (memberIds.isEmpty) return;

    final noticeSnap = await _noticesRef(teamId).doc(noticeId).get();
    if (!noticeSnap.exists) return;
    final data = noticeSnap.data()!;
    final targetDate = (data['targetDate'] as Timestamp?)?.toDate();
    final dateStr =
        targetDate != null ? '${targetDate.month}/${targetDate.day}' : '';
    final slots = (data['slots'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final slot = slots.firstWhere(
          (s) => s['groundId'] == groundId,
          orElse: () => {'groundName': groundId},
        );
    final groundName = slot['groundName'] as String? ?? groundId;
    final reservedForType = data['reservedForType'] as String? ?? 'class';
    final typeLabel = reservedForType == 'class' ? '수업' : '매치';

    await _notificationsRef(teamId).add({
      'title': '구장 예약 성공',
      'message': '$userName님이 $dateStr $typeLabel · $groundName 예약 성공!',
      'type': 'reservationSuccess',
      'relatedId': noticeId,
      'toUserId': memberIds,
      'isSent': false,
      'sendAt': FieldValue.serverTimestamp(),
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// 예약 실패 보고
  Future<void> reportFailed({
    required String teamId,
    required String noticeId,
    required String groundId,
    required String userId,
  }) async {
    final noticeRef = _noticesRef(teamId).doc(noticeId);

    await firestore.runTransaction((tx) async {
      final noticeSnap = await tx.get(noticeRef);
      if (!noticeSnap.exists) throw Exception('예약 공지가 존재하지 않습니다');

      final data = noticeSnap.data()!;
      final slots = (data['slots'] as List?)
              ?.map((e) => Map<String, dynamic>.from(e as Map))
              .toList() ??
          [];

      final slotIndex = slots.indexWhere((s) => s['groundId'] == groundId);
      if (slotIndex < 0) throw Exception('해당 구장을 찾을 수 없습니다');

      final slot = slots[slotIndex];
      if (slot['result'] == 'success') {
        throw Exception('이미 예약 성공 처리되었습니다');
      }

      if (slot['managers'] == null ||
          !(slot['managers'] as List).contains(userId)) {
        throw Exception('해당 구장 담당자가 아닙니다');
      }

      slot['result'] = 'failed';
      slot['successBy'] = userId;
      slot['successAt'] = FieldValue.serverTimestamp();

      final allReported = slots.every((s) =>
          s['result'] == 'success' || s['result'] == 'failed');
      if (allReported) {
        tx.update(noticeRef, {'slots': slots, 'status': 'completed'});
      } else {
        tx.update(noticeRef, {'slots': slots});
      }
    });
  }

  /// 예약 공지 완료 처리 (모든 task 결과 보고 완료 시)
  Future<void> completeNotice(String teamId, String noticeId) async {
    final noticeRef = _noticesRef(teamId).doc(noticeId);
    final snap = await noticeRef.get();
    if (!snap.exists) throw Exception('예약 공지가 존재하지 않습니다');

    final data = snap.data()!;
    final slots = (data['slots'] as List?) ?? [];
    final allReported = slots.every((s) {
      final m = s as Map<String, dynamic>;
      return m['result'] == 'success' || m['result'] == 'failed';
    });

    if (allReported) {
      await noticeRef.update({'status': 'completed'});
    }
  }

  /// 예약 공지 업데이트
  Future<void> updateNotice(
    String teamId,
    String noticeId,
    Map<String, dynamic> data,
  ) async {
    await _noticesRef(teamId).doc(noticeId).update(data);
  }
}
