import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'app/app.dart';
import 'app/providers/firebase_ready_provider.dart';
import 'firebase_options.dart';

/// FCM: 앱 종료 상태에서 알림 수신 시 (탭하여 앱 열기 전 호출)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  if (kDebugMode) {
    // ignore: avoid_print
    print('[FCM] 백그라운드 메시지: ${message.messageId}');
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('ko_KR');
  final firebaseReady = await _initializeFirebase();

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

    // FCM 백그라운드 핸들러 등록
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Firestore 오프라인 캐시 (네트워크 불안정 시에도 캐시된 데이터 표시)
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );

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
