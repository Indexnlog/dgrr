import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_application_1/models/reservation/reservation_model.dart';

class ReservationCard extends StatelessWidget {
  final ReservationModel reservation;
  final VoidCallback? onTap;

  const ReservationCard({super.key, required this.reservation, this.onTap});

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat(
      'yyyy년 MM월 dd일',
    ).format(reservation.date.toDate());
    final timeStr = '${reservation.startTime} ~ ${reservation.endTime}';
    final isPaid = reservation.paymentStatus == 'paid';

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: ListTile(
        onTap: onTap,
        leading: Icon(
          Icons.sports_soccer,
          color: reservation.status == 'canceled' ? Colors.grey : Colors.green,
        ),
        title: Text('$dateStr ($timeStr)'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text('구장 ID: ${reservation.groundId}'),
            Text(
              '대상: ${reservation.reservedForType} (${reservation.reservedForId})',
            ),
            if (reservation.memo.isNotEmpty)
              Text(
                '메모: ${reservation.memo}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              reservation.status == 'reserved' ? '예약됨' : '취소됨',
              style: TextStyle(
                color: reservation.status == 'reserved'
                    ? Colors.blue
                    : Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              isPaid ? '결제완료' : '미결제',
              style: TextStyle(
                color: isPaid ? Colors.green : Colors.orange,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
