import 'package:flutter/material.dart';

class NoticeManagementPage extends StatelessWidget {
  const NoticeManagementPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('📋 공지 관리')),
      body: const Center(
        child: Text('📋 공지 관리 페이지 (추후 구현 예정)', style: TextStyle(fontSize: 18)),
      ),
    );
  }
}
