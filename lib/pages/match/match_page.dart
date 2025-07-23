import 'package:flutter/material.dart';

class MatchPage extends StatelessWidget {
  const MatchPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('매치')),
      body: const Center(child: Text('매치 화면')),
    );
  }
}
