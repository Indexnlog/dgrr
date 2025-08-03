import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:flutter_application_1/models/reservation/reservation_model.dart';
import 'package:flutter_application_1/pages/reservations/reservation_detail_page.dart';

class ReservationListPage extends StatefulWidget {
  const ReservationListPage({super.key});

  @override
  State<ReservationListPage> createState() => _ReservationListPageState();
}

class _ReservationListPageState extends State<ReservationListPage> {
  String? _teamId;

  @override
  void initState() {
    super.initState();
    _loadTeamId();
  }

  /// ✅ 유저가 속한 팀 ID를 불러옴
  Future<void> _loadTeamId() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final teamsSnapshot = await FirebaseFirestore.instance
        .collection('teams')
        .get();

    for (var doc in teamsSnapshot.docs) {
      final memberDoc = await doc.reference
          .collection('members')
          .doc(uid)
          .get();

      if (memberDoc.exists) {
        setState(() {
          _teamId = doc.id;
        });
        return;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_teamId == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('구장 예약 목록')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('teams')
            .doc(_teamId)
            .collection('reservations')
            .orderBy('date', descending: false)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;
          if (docs.isEmpty) {
            return const Center(child: Text('예약 내역이 없습니다.'));
          }

          final reservations = docs
              .map((doc) => ReservationModel.fromDoc(doc))
              .toList();

          return ListView.builder(
            itemCount: reservations.length,
            itemBuilder: (context, index) {
              final r = reservations[index];
              final dateStr = r.date.toDate().toLocal().toString().split(
                ' ',
              )[0];

              return ListTile(
                title: Text('$dateStr ${r.startTime} ~ ${r.endTime}'),
                subtitle: Text('구장 ID: ${r.groundId}'),
                trailing: Text(
                  r.status == 'cancelled' ? '취소됨' : '예약됨',
                  style: TextStyle(
                    color: r.status == 'cancelled' ? Colors.red : Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ReservationDetailPage(reservation: r),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
