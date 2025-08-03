import 'package:flutter/material.dart';
import 'package:flutter_application_1/models/reservation_model.dart';
import 'package:intl/intl.dart';

class ReservationDetailPage extends StatelessWidget {
  final ReservationModel reservation;

  const ReservationDetailPage({super.key, required this.reservation});

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat(
      'yyyy년 MM월 dd일',
    ).format(reservation.date.toDate());

    return Scaffold(
      appBar: AppBar(title: const Text('예약 상세')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _infoRow('팀 ID', reservation.teamId),
            _infoRow('날짜', dateStr),
            _infoRow('시간', '${reservation.startTime} ~ ${reservation.endTime}'),
            _infoRow('구장 ID', reservation.groundId),
            _infoRow('예약자', reservation.reservedBy),
            _infoRow('예약 대상 ID', reservation.reservedForId),
            _infoRow('대상 타입', reservation.reservedForType),
            _infoRow('상태', _statusText(reservation.status)),
            _infoRow('결제 상태', _paymentStatusText(reservation.paymentStatus)),
            if (reservation.memo.isNotEmpty) _infoRow('메모', reservation.memo),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$title:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(color: Colors.black87)),
          ),
        ],
      ),
    );
  }

  String _statusText(String status) {
    switch (status) {
      case 'reserved':
        return '예약됨';
      case 'cancelled':
        return '취소됨';
      case 'used':
        return '사용완료';
      default:
        return status;
    }
  }

  String _paymentStatusText(String paymentStatus) {
    switch (paymentStatus) {
      case 'unpaid':
        return '미결제';
      case 'paid':
        return '결제 완료';
      default:
        return paymentStatus;
    }
  }
}
