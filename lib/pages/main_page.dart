import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

// 페이지 import
import 'home/home_tab.dart';
import 'schedule/schedule_page.dart';
import 'profile/profile_page.dart';
import 'auth/login_page.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _currentIndex = 0;

  final List<Widget> _tabs = const [HomeTab(), SchedulePage(), ProfilePage()];

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    // 🔐 로그인 안 되어 있으면 로그인 페이지로
    if (user == null) return const LoginPage();

    return Scaffold(
      appBar: AppBar(
        title: const Text('지구공'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginPage()),
                  (route) => false,
                );
              }
            },
          ),
        ],
      ),
      body: _tabs[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: Colors.deepPurple,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: '홈'),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_month),
            label: '일정',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: '내 정보'),
        ],
      ),
    );
  }
}
