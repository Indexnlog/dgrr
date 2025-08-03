import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:flutter_application_1/models/class/class_model.dart'; // ⚠️ 경로 확인
import 'package:flutter_application_1/pages/classes/class_detail_page.dart'; // ✅ 상세 페이지 import
import 'package:flutter_application_1/services/firestore/schedule_service.dart'; // ✅ 확정 함수 import

class ClassListPage extends StatefulWidget {
  const ClassListPage({super.key});

  @override
  State<ClassListPage> createState() => _ClassListPageState();
}

class _ClassListPageState extends State<ClassListPage> {
  String? _teamId;

  @override
  void initState() {
    super.initState();
    _loadTeamId();
  }

  /// ✅ 현재 로그인한 사용자의 팀 ID 조회
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
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('수업 일정'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check_circle_outline),
            tooltip: '다음달 일정 확정',
            onPressed: () async {
              await ScheduleService.confirmNextMonthSchedules(teamId: _teamId!);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('다음달 일정이 확정되었습니다.')),
                );
              }
            },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('teams')
            .doc(_teamId)
            .collection('classes')
            .orderBy('date', descending: false)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data?.docs ?? [];

          if (docs.isEmpty) {
            return const Center(child: Text('등록된 수업이 없습니다.'));
          }

          final classList = docs.map((doc) => ClassModel.fromDoc(doc)).toList();

          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: classList.length,
            separatorBuilder: (_, __) => const Divider(),
            itemBuilder: (context, index) {
              final c = classList[index];
              return ListTile(
                leading: const Icon(Icons.school),
                title: Text('${c.date} ${c.startTime}~${c.endTime}'),
                subtitle: Text(c.location),
                trailing: Text(
                  c.status == 'cancelled'
                      ? '취소됨'
                      : (c.status == 'draft' ? '임시저장' : '진행중'),
                  style: TextStyle(
                    color: c.status == 'cancelled'
                        ? Colors.red
                        : (c.status == 'draft' ? Colors.orange : Colors.green),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ClassDetailPage(classModel: c),
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
