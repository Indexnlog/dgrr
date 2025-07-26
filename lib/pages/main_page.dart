import 'package:flutter/material.dart';

// 각 탭별 페이지 import
import 'home/home_page.dart';
import 'schedule/schedule_page.dart';
import 'match/match_page.dart';
import 'profile/profile_page.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _selectedIndex = 0;

  // ✅ 각 탭에 연결할 페이지 리스트
  final List<Widget> _pages = const [
    HomePage(),
    SchedulePage(), // 일정 탭
    MatchPage(), // 매치 탭
    ProfilePage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      // 🔥 디버깅용 로그
      debugPrint('✅ 탭 변경: index=$index');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Colors.deepPurple,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed, // 아이콘이 4개라 fixed로
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: '홈'),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: '일정',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.sports_soccer), label: '매치'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: '개인'),
        ],
      ),
    );
  }
}
