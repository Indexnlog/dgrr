import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/reservation_model.dart';

/// 예약 Firestore 데이터소스
class ReservationRemoteDataSource {
  ReservationRemoteDataSource({required this.firestore});

  final FirebaseFirestore firestore;

  CollectionReference<Map<String, dynamic>> _resvRef(String teamId) =>
      firestore.collection('teams').doc(teamId).collection('reservations');

  /// 다가오는 예약 목록
  Stream<List<ReservationModel>> watchUpcomingReservations(String teamId) {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);

    return _resvRef(teamId)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(todayStart))
        .orderBy('date')
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) =>
                ReservationModel.fromFirestore(doc.id, doc.data()))
            .toList());
  }

  /// 예약 생성
  Future<String> createReservation(
    String teamId,
    ReservationModel reservation,
  ) async {
    final doc = await _resvRef(teamId).add(reservation.toFirestore());
    return doc.id;
  }

  /// 예약 상태 업데이트
  Future<void> updateReservation(
    String teamId,
    String reservationId,
    Map<String, dynamic> data,
  ) async {
    await _resvRef(teamId).doc(reservationId).update(data);
  }
}
