import 'package:flutter/material.dart';
import 'home/home_page.dart';
// ⬇️ 기존 class_page.dart 대신 schedule_page.dart를 import
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

  // ✅ 여기서 ClassPage를 SchedulePage로 변경
  final List<Widget> _pages = [
    const HomePage(),
    const SchedulePage(), // ✅ 일정 탭
    const MatchPage(),
    const ProfilePage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
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
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: '홈'),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: '일정', // ✨ 여기 라벨도 변경 가능
          ),
          BottomNavigationBarItem(icon: Icon(Icons.sports_soccer), label: '매치'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: '개인'),
        ],
      ),
    );
  }
}
