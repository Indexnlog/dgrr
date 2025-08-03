import 'package:flutter/material.dart';
import 'package:flutter_application_1/pages/reservations/widgets/reservation_form.dart';

class ReservationAddPage extends StatelessWidget {
  final String teamId;

  const ReservationAddPage({super.key, required this.teamId});

  @override
  Widget build(BuildContext context) {
    return ReservationForm(
      teamId: teamId,
      initialData: null, // 등록이므로 초기 데이터는 없음
    );
  }
}
