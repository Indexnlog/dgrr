import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../providers/team_provider.dart';
import 'login_page.dart'; // ✅ 로그인 페이지로 이동

class SelectTeamPage extends StatelessWidget {
  const SelectTeamPage({super.key});

  Future<void> _onTeamSelected(BuildContext context, String teamId) async {
    // ✅ Provider에 저장
    Provider.of<TeamProvider>(context, listen: false).setTeamId(teamId);

    // ✅ SharedPreferences에 저장
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selectedTeamId', teamId);

    // ✅ LoginPage로 이동
    if (context.mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('팀 선택')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('teams').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('등록된 팀이 없습니다.'));
          }

          final teams = snapshot.data!.docs;

          return ListView.builder(
            itemCount: teams.length,
            itemBuilder: (context, index) {
              final team = teams[index];
              final teamId = team.id;
              final name = team['name'];
              final logoUrl = team['logoUrl'];

              return ListTile(
                leading: CircleAvatar(
                  backgroundImage: NetworkImage(logoUrl),
                  radius: 24,
                ),
                title: Text(name),
                onTap: () => _onTeamSelected(context, teamId),
              );
            },
          );
        },
      ),
    );
  }
}
