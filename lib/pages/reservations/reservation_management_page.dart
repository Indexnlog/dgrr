import 'package:flutter/material.dart';

class ReservationManagementPage extends StatelessWidget {
  const ReservationManagementPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('🏟 구장 예약 관리')),
      body: const Center(
        child: Text(
          '🏟 구장 예약 관리 페이지 (추후 구현 예정)',
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
