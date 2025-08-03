import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';

import '../../providers/team_provider.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final teamId = context.read<TeamProvider>().teamId;
    final user = FirebaseAuth.instance.currentUser;

    if (teamId == null || user == null) {
      return const Scaffold(
        body: Center(child: Text('⚠️ 로그인 또는 팀 선택이 필요합니다.')),
      );
    }

    final memberRef = FirebaseFirestore.instance
        .collection('teams')
        .doc(teamId)
        .collection('members')
        .doc(user.uid);

    return Scaffold(
      appBar: AppBar(title: const Text('👤 내 정보')),
      body: FutureBuilder<DocumentSnapshot>(
        future: memberRef.get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('❌ 회원 정보를 찾을 수 없습니다.'));
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;

          String getField(String key) =>
              data[key]?.toString().trim().isNotEmpty == true
              ? data[key].toString()
              : '-';

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text(
                '📄 기본 정보',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),

              ListTile(
                title: const Text('이름'),
                subtitle: Text(getField('name')),
              ),
              ListTile(
                title: const Text('유니폼 이름'),
                subtitle: Text(getField('uniformName')),
              ),
              ListTile(
                title: const Text('등번호'),
                subtitle: Text(getField('number')),
              ),
              ListTile(
                title: const Text('소속'),
                subtitle: Text(getField('department')),
              ),
              ListTile(
                title: const Text('상태'),
                subtitle: Text(getField('status')),
              ),
              const SizedBox(height: 24),

              // 추후 편집 기능 추가 시
              // ElevatedButton(
              //   onPressed: () {
              //     Navigator.push(...); // 수정 페이지로 이동
              //   },
              //   child: const Text('내 정보 수정'),
              // ),
            ],
          );
        },
      ),
    );
  }
}
