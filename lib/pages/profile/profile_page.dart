import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';

import '../../providers/team_provider.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final teamId = Provider.of<TeamProvider>(context, listen: false).teamId;
    final user = FirebaseAuth.instance.currentUser;

    if (user == null || teamId == null) {
      return const Scaffold(body: Center(child: Text('로그인이 필요합니다')));
    }

    final memberRef = FirebaseFirestore.instance
        .collection('teams')
        .doc(teamId)
        .collection('members')
        .doc(user.uid);

    return Scaffold(
      appBar: AppBar(title: const Text('개인 정보')),
      body: FutureBuilder<DocumentSnapshot>(
        future: memberRef.get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('회원 정보를 찾을 수 없습니다.'));
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text('이름: ${data['name'] ?? '없음'}'),
              Text('유니폼 이름: ${data['uniformName'] ?? '없음'}'),
              Text('등번호: ${data['number'] ?? '없음'}'),
              Text('소속: ${data['department'] ?? '없음'}'),
              Text('상태: ${data['status'] ?? '없음'}'),
              // 필요한 항목 더 추가 가능
            ],
          );
        },
      ),
    );
  }
}
