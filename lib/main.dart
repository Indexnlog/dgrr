import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart'; // ✅ Firebase 옵션 파일
import 'pages/auth/login_page.dart'; // ✅ 로그인 페이지
import 'pages/main_page.dart'; // ✅ 메인 페이지 (바텀네비)
import 'pages/manage/class_add_page.dart'; // ✅ 수업 등록 페이지
import 'pages/manage/match_add_page.dart'; // ✅ 매치 등록 페이지

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // ✅ Firebase 프로젝트 초기화
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
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
        useMaterial3: true,
      ),
      // ✅ 라우트 등록
      routes: {
        '/classAdd': (context) => const ClassAddPage(),
        '/matchAdd': (context) => const MatchAddPage(),
      },
      // 👉 시작 화면 (로그인 후 MainPage로 이동하도록 구현되어야 함)
      home: const LoginPage(),
    );
  }
}
