import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'firebase_options.dart';
import 'providers/team_provider.dart';
import 'providers/user_role_provider.dart';

import 'pages/main_page.dart';
import 'pages/auth/login_page.dart';
import 'pages/auth/select_team_page.dart';
import 'pages/auth/init_page.dart';
import 'pages/auth/splash_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    
    final prefs = await SharedPreferences.getInstance();
    final savedTeamId = prefs.getString('selectedTeamId');

    runApp(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(
            create: (_) {
              final teamProvider = TeamProvider();
              if (savedTeamId != null && savedTeamId.isNotEmpty) {
                teamProvider.setTeamId(savedTeamId);
              }
              return teamProvider;
            },
          ),
          ChangeNotifierProvider(create: (_) => UserRoleProvider()),
        ],
        child: const MyApp(),
      ),
    );
  } catch (e) {
    // Firebase 초기화 실패 시 에러 앱 실행
    runApp(ErrorApp(error: e.toString()));
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '지구공',
      debugShowCheckedModeBanner: false,
      
      // 🎨 테마 설정
      theme: ThemeData(
        primarySwatch: Colors.green,
        primaryColor: const Color(0xFF2E7D32), // 축구장 잔디색
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF2E7D32),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2E7D32),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        cardTheme: CardTheme(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      
      // 🌏 한국어 설정
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('ko', 'KR'),
        Locale('en', 'US'),
      ],
      locale: const Locale('ko', 'KR'),
      
      // 🛣️ 라우팅 설정
      home: const SplashPage(),
      routes: {
        '/login': (context) => const LoginPage(),
        '/select-team': (context) => const SelectTeamPage(),
        '/init': (context) => const InitPage(),
        '/main': (context) => const MainPage(),
      },
      
      // 🚨 라우트 에러 처리
      onUnknownRoute: (settings) {
        return MaterialPageRoute(
          builder: (context) => const Scaffold(
            body: Center(
              child: Text('페이지를 찾을 수 없습니다'),
            ),
          ),
        );
      },
    );
  }
}

// 🚨 Firebase 초기화 실패 시 보여줄 에러 앱
class ErrorApp extends StatelessWidget {
  final String error;
  
  const ErrorApp({super.key, required this.error});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red,
              ),
              const SizedBox(height: 16),
              const Text(
                '앱 초기화 중 오류가 발생했습니다',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                error,
                style: const TextStyle(color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  // 앱 재시작 로직 또는 문의 페이지로 이동
                },
                child: const Text('다시 시도'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}