import 'package:cloud_firestore/cloud_firestore.dart';

class ReservationModel {
  final String id;
  final Timestamp date;
  final String startTime;
  final String endTime;
  final String groundId;
  final String reservedBy;
  final String reservedForId;
  final String reservedForType;
  final String status;
  final String teamId;
  final String paymentStatus;
  final String memo;

  ReservationModel({
    required this.id,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.groundId,
    required this.reservedBy,
    required this.reservedForId,
    required this.reservedForType,
    required this.status,
    required this.teamId,
    required this.paymentStatus,
    required this.memo,
  });

  factory ReservationModel.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ReservationModel(
      id: doc.id,
      date: data['date'] ?? Timestamp.now(),
      startTime: data['startTime'] ?? '',
      endTime: data['endTime'] ?? '',
      groundId: data['groundId'] ?? '',
      reservedBy: data['reservedBy'] ?? '',
      reservedForId: data['reservedForId'] ?? '',
      reservedForType: data['reservedForType'] ?? '',
      status: data['status'] ?? 'reserved',
      teamId: data['teamId'] ?? '',
      paymentStatus: data['paymentStatus'] ?? 'unpaid',
      memo: data['memo'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'date': date,
      'startTime': startTime,
      'endTime': endTime,
      'groundId': groundId,
      'reservedBy': reservedBy,
      'reservedForId': reservedForId,
      'reservedForType': reservedForType,
      'status': status,
      'teamId': teamId,
      'paymentStatus': paymentStatus,
      'memo': memo,
    };
  }
}
