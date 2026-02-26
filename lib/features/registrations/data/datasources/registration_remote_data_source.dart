import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/registration.dart';
import '../models/registration_model.dart';

/// 등록 Firestore 데이터소스
class RegistrationRemoteDataSource {
  RegistrationRemoteDataSource({required this.firestore});

  final FirebaseFirestore firestore;

  CollectionReference<Map<String, dynamic>> _regsRef(String teamId) =>
      firestore.collection('teams').doc(teamId).collection('registrations');

  /// 특정 시즌(eventId) 등록 목록 실시간 스트림
  Stream<List<RegistrationModel>> watchRegistrations(
    String teamId,
    String eventId,
  ) {
    return _regsRef(teamId)
        .where('eventId', isEqualTo: eventId)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) =>
                RegistrationModel.fromFirestore(doc.id, doc.data()))
            .toList());
  }

  /// 내 최근 등록 상태 조회
  Stream<List<RegistrationModel>> watchMyRegistrations(
    String teamId,
    String userId,
  ) {
    return _regsRef(teamId)
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(6)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) =>
                RegistrationModel.fromFirestore(doc.id, doc.data()))
            .toList());
  }

  /// 등록 생성/업데이트 (upsert by eventId + userId)
  Future<void> upsertRegistration(
    String teamId,
    RegistrationModel reg,
  ) async {
    final existing = await _regsRef(teamId)
        .where('eventId', isEqualTo: reg.eventId)
        .where('userId', isEqualTo: reg.userId)
        .limit(1)
        .get();

    if (existing.docs.isNotEmpty) {
      await _regsRef(teamId)
          .doc(existing.docs.first.id)
          .update(reg.toFirestore());
    } else {
      await _regsRef(teamId).add(reg.toFirestore());
    }
  }

  /// 납부 상태 토글 (총무용)
  Future<void> updatePaymentStatus(
    String teamId,
    String registrationId,
    String status,
  ) async {
    await _regsRef(teamId).doc(registrationId).update({
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// 월별 등록 여부 투표 결과 반영 (등록/휴회/미등록)
  /// seasonId: yyyy-MM (예: 2026-03)
  Future<void> upsertMembershipRegistration({
    required String teamId,
    required String seasonId,
    required String userId,
    required MembershipStatus membershipStatus,
    String? userName,
    int? uniformNo,
    String? photoUrl,
  }) async {
    final existing = await _regsRef(teamId)
        .where('eventId', isEqualTo: seasonId)
        .where('userId', isEqualTo: userId)
        .limit(1)
        .get();

    final now = DateTime.now();
    final reg = RegistrationModel(
      registrationId: existing.docs.isNotEmpty ? existing.docs.first.id : '',
      eventId: seasonId,
      userId: userId,
      userName: userName,
      uniformNo: uniformNo,
      photoUrl: photoUrl,
      type: RegistrationType.class_,
      status: RegistrationStatus.pending,
      membershipStatus: membershipStatus,
      createdAt: existing.docs.isNotEmpty
          ? (existing.docs.first.data()['createdAt'] as Timestamp?)?.toDate()
          : now,
      updatedAt: now,
    );

    if (existing.docs.isNotEmpty) {
      await _regsRef(teamId)
          .doc(existing.docs.first.id)
          .update(reg.toFirestore());
    } else {
      await _regsRef(teamId).add(reg.toFirestore());
    }
  }
}
