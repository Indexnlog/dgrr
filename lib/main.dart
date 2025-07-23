// main.dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';          // ✅ Firebase 옵션 파일 임포트
import 'pages/auth/login_page.dart';         // ✅ 로그인 페이지 임포트

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // ✅ Firebase 프로젝트 초기화 시 옵션 명시
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: '지구공',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const LoginPage(), // ✅ 앱 시작 시 로그인 페이지
    );
  }
}
