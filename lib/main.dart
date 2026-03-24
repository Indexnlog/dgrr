import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'app/app.dart';
import 'app/providers/firebase_ready_provider.dart';
import 'core/observability/crashlytics_service.dart';
import 'firebase_options.dart';

/// FCM: 앱 종료 상태에서 알림 수신 시 (탭하여 앱 열기 전 호출)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  if (kDebugMode) {
    debugPrint('[FCM] 백그라운드 메시지: ${message.messageId}');
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('ko_KR');
  final firebaseReady = await _initializeFirebase();

  // 상태바 투명 + 밝은 아이콘 (파란 상단바와 어울리도록)
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
    ),
  );

  runApp(
    ProviderScope(
      overrides: [
        firebaseReadyProvider.overrideWithValue(firebaseReady),
      ],
      child: const DgrrApp(),
    ),
  );
}

Future<bool> _initializeFirebase() async {
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    await CrashlyticsService.initialize();
    _bindGlobalCrashHandlers();

    // App Check: 프로덕션에서 비정상 클라이언트 호출 차단
    await _initializeAppCheck();

    // FCM 백그라운드 핸들러 등록
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Firestore 오프라인 캐시 설정
    // 웹에서 persistence 활성화 시 규칙 거부된 write/read가 Future를 영원히 hang시키는 문제로
    // 웹은 명시적으로 비활성화
    if (kIsWeb) {
      FirebaseFirestore.instance.settings = const Settings(
        persistenceEnabled: false,
      );
    } else {
      FirebaseFirestore.instance.settings = const Settings(
        persistenceEnabled: true,
        cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
      );
    }

    // 에뮬레이터는 opt-in: --dart-define=USE_FIREBASE_EMULATOR=true 일 때만 연결 (기본: 실제 Firebase)
    if (kDebugMode &&
        const bool.fromEnvironment('USE_FIREBASE_EMULATOR', defaultValue: false)) {
      try {
        await _connectToEmulators();
      } catch (_) {
        // 에뮬레이터 미실행 시 실제 Firebase 사용
      }
    }

    return true;
  } catch (_) {
    return false;
  }
}

void _bindGlobalCrashHandlers() {
  if (kIsWeb) {
    return;
  }

  final previousHandler = FlutterError.onError;
  FlutterError.onError = (details) {
    previousHandler?.call(details);
    FirebaseCrashlytics.instance.recordFlutterFatalError(details);
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };
}

Future<void> _initializeAppCheck() async {
  // 에뮬레이터 사용 시 App Check는 비활성화(로컬 개발 편의)
  final useEmulator = const bool.fromEnvironment(
    'USE_FIREBASE_EMULATOR',
    defaultValue: false,
  );
  if (useEmulator) {
    if (kDebugMode) {
      debugPrint('[AppCheck] 에뮬레이터 모드 - App Check 초기화 생략');
    }
    return;
  }

  try {
    final webSiteKey = const String.fromEnvironment(
      'FIREBASE_APP_CHECK_WEB_SITE_KEY',
      defaultValue: '',
    );

    // 웹 사이트 키가 없으면 앱 시작은 유지하고 로그만 남긴다.
    if (kIsWeb && webSiteKey.isEmpty) {
      if (kDebugMode) {
        debugPrint('[AppCheck] 웹 site key 미설정 - App Check 비활성');
      }
      return;
    }

    await FirebaseAppCheck.instance.activate(
      webProvider: kIsWeb ? ReCaptchaV3Provider(webSiteKey) : null,
      // 디버그 빌드: debug provider / 릴리스: Play Integrity
      androidProvider: kDebugMode
          ? AndroidProvider.debug
          : AndroidProvider.playIntegrity,
      // 디버그 빌드: debug provider / 릴리스: App Attest 우선
      appleProvider: kDebugMode
          ? AppleProvider.debug
          : AppleProvider.appAttestWithDeviceCheckFallback,
    );

    if (kDebugMode) {
      debugPrint('[AppCheck] 초기화 완료');
    }
  } catch (e) {
    // 초기 설정 단계에서는 앱 부팅을 막지 않고 로그만 남긴다.
    if (kDebugMode) {
      debugPrint('[AppCheck] 초기화 실패: $e');
    }
  }
}

Future<void> _connectToEmulators() async {
  // Android 에뮬레이터 → 10.0.2.2 (호스트 머신의 localhost를 가리킴)
  // iOS 시뮬레이터 / macOS / Web → localhost
  // 실물 기기 → 아이맥의 로컬 IP (예: 192.168.x.x)로 교체 필요
  final host = defaultTargetPlatform == TargetPlatform.android
      ? '10.0.2.2'
      : 'localhost';

  FirebaseFirestore.instance.useFirestoreEmulator(host, 8080);
  await FirebaseAuth.instance.useAuthEmulator(host, 9099);
}
