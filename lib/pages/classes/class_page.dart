import 'package:flutter/material.dart';
import 'package:flutter_application_1/pages/classes/class_list_page.dart';
import 'package:flutter_application_1/pages/classes/class_add_page.dart';

class ClassPage extends StatelessWidget {
  const ClassPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('📘 수업 관리'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: '수업 등록',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ClassAddPage()),
              );
            },
          ),
        ],
      ),
      body: const ClassListPage(), // 기본은 수업 리스트 보여주기
    );
  }
}
