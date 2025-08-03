import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_application_1/models/reservation/reservation_model.dart';

class ReservationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// 🔹 예약 추가
  Future<void> addReservation(
    String teamId,
    ReservationModel reservation,
  ) async {
    await _firestore
        .collection('teams')
        .doc(teamId)
        .collection('reservations')
        .add(reservation.toMap());
  }

  /// 🔹 예약 수정
  Future<void> updateReservation(
    String teamId,
    ReservationModel reservation,
  ) async {
    await _firestore
        .collection('teams')
        .doc(teamId)
        .collection('reservations')
        .doc(reservation.id)
        .update(reservation.toMap());
  }

  /// 🔹 예약 삭제
  Future<void> deleteReservation(String teamId, String reservationId) async {
    await _firestore
        .collection('teams')
        .doc(teamId)
        .collection('reservations')
        .doc(reservationId)
        .delete();
  }

  /// 🔹 예약 목록 조회 (날짜 기준 정렬)
  Stream<List<ReservationModel>> getReservations(String teamId) {
    return _firestore
        .collection('teams')
        .doc(teamId)
        .collection('reservations')
        .orderBy('date')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => ReservationModel.fromDoc(doc))
              .toList(),
        );
  }

  /// 🔹 예약 단일 조회
  Future<ReservationModel?> getReservationById(
    String teamId,
    String reservationId,
  ) async {
    final doc = await _firestore
        .collection('teams')
        .doc(teamId)
        .collection('reservations')
        .doc(reservationId)
        .get();

    if (doc.exists) {
      return ReservationModel.fromDoc(doc);
    } else {
      return null;
    }
  }
}
