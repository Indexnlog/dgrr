import 'package:flutter/material.dart';

class ClassPage extends StatelessWidget {
  const ClassPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('수업')),
      body: const Center(child: Text('수업 화면')),
    );
  }
}
