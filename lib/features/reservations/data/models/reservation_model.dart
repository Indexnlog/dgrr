import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/reservation.dart';

/// 경기장 예약 모델 (Firestore 변환 포함)
class ReservationModel extends Reservation {
  const ReservationModel({
    required super.reservationId,
    required super.groundId,
    super.reservedForType,
    super.reservedForId,
    super.date,
    super.startTime,
    super.endTime,
    super.status,
    super.paymentStatus,
    super.reservedBy,
    super.memo,
    super.createdAt,
  });

  factory ReservationModel.fromFirestore(
    String id,
    Map<String, dynamic> json,
  ) {
    return ReservationModel(
      reservationId: id,
      groundId: json['groundId'] as String? ?? '',
      reservedForType:
          ReservationForType.fromString(json['reservedForType'] as String?),
      reservedForId: json['reservedForId'] as String?,
      date: (json['date'] as Timestamp?)?.toDate(),
      startTime: json['startTime'] as String?,
      endTime: json['endTime'] as String?,
      status: ReservationStatus.fromString(json['status'] as String?),
      paymentStatus: PaymentStatus.fromString(json['paymentStatus'] as String?),
      reservedBy: json['reservedBy'] as String?,
      memo: json['memo'] as String?,
      createdAt: (json['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'groundId': groundId,
      if (reservedForType != null) 'reservedForType': reservedForType!.value,
      if (reservedForId != null) 'reservedForId': reservedForId,
      if (date != null) 'date': Timestamp.fromDate(date!),
      if (startTime != null) 'startTime': startTime,
      if (endTime != null) 'endTime': endTime,
      if (status != null) 'status': status!.value,
      if (paymentStatus != null) 'paymentStatus': paymentStatus!.value,
      if (reservedBy != null) 'reservedBy': reservedBy,
      if (memo != null) 'memo': memo,
      if (createdAt != null) 'createdAt': Timestamp.fromDate(createdAt!),
    };
  }
}
