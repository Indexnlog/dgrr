import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'firebase_options.dart';
import 'providers/team_provider.dart';
import 'providers/user_role_provider.dart';
import 'services/get_it_service.dart'; // 의존성 주입
import 'utils/app_theme.dart'; // 테마 분리

import 'pages/main_page.dart';
import 'pages/auth/login_page.dart';
import 'pages/auth/select_team_page.dart';
import 'pages/auth/init_page.dart';
import 'pages/auth/splash_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 🎨 상태바 스타일 설정
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );
  
  // 📱 세로 모드 고정
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  try {
    // 🔥 Firebase 초기화
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    
    // 🚨 Crashlytics 설정 (릴리즈 모드에서만)
    if (!kDebugMode) {
      FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
      PlatformDispatcher.instance.onError = (error, stack) {
        FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
        return true;
      };
    }
    
    // 🔧 의존성 주입 초기화
    await setupGetIt();
    
    // 💾 저장된 팀 정보 로드
    final prefs = await SharedPreferences.getInstance();
    final savedTeamId = prefs.getString('selectedTeamId');
    final savedUserId = prefs.getString('userId');

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
          ChangeNotifierProvider(
            create: (_) {
              final userRoleProvider = UserRoleProvider();
              if (savedUserId != null) {
                // 저장된 사용자 역할 복원
                userRoleProvider.initializeFromStorage(savedUserId);
              }
              return userRoleProvider;
            },
          ),
        ],
        child: const MyApp(),
      ),
    );
  } catch (e, stackTrace) {
    // 🚨 초기화 실패 로깅
    debugPrint('App initialization failed: $e');
    if (!kDebugMode) {
      FirebaseCrashlytics.instance.recordError(e, stackTrace);
    }
    
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
      
      // 🎨 테마 설정 (분리된 파일)
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme, // 다크모드 지원
      themeMode: ThemeMode.system, // 시스템 설정 따름
      
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
      routes: _buildRoutes(),
      
      // 🚨 라우트 에러 처리
      onUnknownRoute: _buildUnknownRoute,
      
      // 🔍 앱 생명주기 관리
      builder: (context, child) {
        return MediaQuery(
          // 📱 텍스트 크기 고정 (접근성 고려하되 레이아웃 깨짐 방지)
          data: MediaQuery.of(context).copyWith(
            textScaleFactor: MediaQuery.of(context).textScaleFactor.clamp(0.8, 1.2),
          ),
          child: child!,
        );
      },
    );
  }

  // 🛣️ 라우트 정의 분리
  Map<String, WidgetBuilder> _buildRoutes() {
    return {
      '/login': (context) => const LoginPage(),
      '/select-team': (context) => const SelectTeamPage(),
      '/init': (context) => const InitPage(),
      '/main': (context) => const MainPage(),
    };
  }

  // 🚨 알 수 없는 라우트 처리
  Route<dynamic> _buildUnknownRoute(RouteSettings settings) {
    return MaterialPageRoute(
      builder: (context) => Scaffold(
        appBar: AppBar(
          title: const Text('오류'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.orange,
              ),
              const SizedBox(height: 16),
              Text(
                '페이지를 찾을 수 없습니다\n(${settings.name})',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pushReplacementNamed('/main'),
                child: const Text('홈으로 이동'),
              ),
            ],
          ),
        ),
      ),
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
      title: '지구공 - 오류',
      theme: AppTheme.lightTheme,
      home: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 80,
                    color: Colors.red,
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    '앱 초기화 중 오류가 발생했습니다',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      error,
                      style: const TextStyle(
                        color: Colors.black54,
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 32),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _restartApp,
                          icon: const Icon(Icons.refresh),
                          label: const Text('다시 시도'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: _contactSupport,
                    child: const Text('고객 지원 문의'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _restartApp() {
    // 앱 재시작 로직
    SystemNavigator.pop(); // Android에서 앱 종료
  }

  void _contactSupport() {
    // 이메일 또는 문의 페이지로 이동
    // url_launcher 패키지 사용
  }
}