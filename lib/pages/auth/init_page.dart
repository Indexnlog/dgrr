import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'login_page.dart';
import 'select_team_page.dart';

class InitPage extends StatelessWidget {
  const InitPage({super.key});

  Future<String?> _getSavedTeamId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('selectedTeamId');
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: _getSavedTeamId(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // 오류 처리
        if (snapshot.hasError) {
          return const Scaffold(body: Center(child: Text('초기화 중 오류 발생')));
        }

        final teamId = snapshot.data;

        // teamId가 저장 안 되어 있으면 → 팀 선택
        if (teamId == null || teamId.isEmpty) {
          return const SelectTeamPage();
        }

        // 이미 선택된 팀이 있으면 → 로그인 페이지로 이동
        return const LoginPage(); // 또는 MainPage()로 바로 가도 됨
      },
    );
  }
}
