import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

import '../models/reservation_notice_model.dart';

/// 예약 공지 Firestore 데이터소스
class ReservationNoticeRemoteDataSource {
  ReservationNoticeRemoteDataSource({required this.firestore});

  final FirebaseFirestore firestore;
  String _requestId(String action) =>
      '${DateTime.now().microsecondsSinceEpoch}_$action';

  CollectionReference<Map<String, dynamic>> _noticesRef(String teamId) =>
      firestore.collection('teams').doc(teamId).collection('reservation_notices');

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
    final callable = FirebaseFunctions.instance.httpsCallable(
      'reportReservationResult',
    );
    await callable.call({
      'teamId': teamId,
      'noticeId': noticeId,
      'groundId': groundId,
      'result': 'success',
      'userId': userId,
      'userName': userName,
      'requestId': _requestId('reservation_success'),
    });
  }

  /// 예약 실패 보고
  Future<void> reportFailed({
    required String teamId,
    required String noticeId,
    required String groundId,
    required String userId,
  }) async {
    final callable = FirebaseFunctions.instance.httpsCallable(
      'reportReservationResult',
    );
    await callable.call({
      'teamId': teamId,
      'noticeId': noticeId,
      'groundId': groundId,
      'result': 'failed',
      'userId': userId,
      'requestId': _requestId('reservation_failed'),
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
