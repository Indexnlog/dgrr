import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_state_provider.dart';
import '../../../teams/presentation/providers/current_team_provider.dart';
import '../../../teams/presentation/providers/team_providers.dart';

/// FCM 초기화 및 토큰 관리 Provider
/// - 권한 요청
/// - 토큰 획득/갱신
/// - Firestore에 토큰 저장 (미납자 Nudge 등 푸시용)
final fcmProvider = Provider<FcmService>((ref) {
  return FcmService(ref);
});

class FcmService {
  FcmService(this._ref);

  final Ref _ref;
  FirebaseMessaging get _messaging => FirebaseMessaging.instance;
  String? _lastToken;

  /// FCM 초기화 (앱 시작 시 호출)
  Future<void> initialize() async {
    // 권한 요청 (iOS, Android 13+)
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.denied) {
      if (kDebugMode) {
        // ignore: avoid_print
        print('[FCM] 알림 권한 거부됨');
      }
      return;
    }

    // 포그라운드 메시지 표시 설정 (iOS)
    if (Platform.isIOS) {
      await _messaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );
    }

    // 토큰 갱신 리스너
    _messaging.onTokenRefresh.listen((token) {
      _lastToken = token;
      _saveTokenToFirestore(token);
    });

    // 초기 토큰
    final token = await _messaging.getToken();
    if (token != null) {
      _lastToken = token;
      await _saveTokenToFirestore(token);
    }

    // 메시지 핸들링
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);
  }

  Future<void> _saveTokenToFirestore(String token) async {
    // ref.read는 ProviderScope 내에서 호출되어야 함
    final uid = _ref.read(currentUserProvider)?.uid;
    final teamId = _ref.read(currentTeamIdProvider);
    if (uid == null || teamId == null) return;

    try {
      await _ref.read(teamRepositoryProvider).updateMemberFcmToken(
            teamId: teamId,
            memberId: uid,
            fcmToken: token,
          );
      if (kDebugMode) {
        // ignore: avoid_print
        print('[FCM] 토큰 저장 완료');
      }
    } catch (e) {
      if (kDebugMode) {
        // ignore: avoid_print
        print('[FCM] 토큰 저장 실패: $e');
      }
    }
  }

  void _handleForegroundMessage(RemoteMessage message) {
    if (kDebugMode) {
      // ignore: avoid_print
      print('[FCM] 포그라운드 메시지: ${message.notification?.title}');
    }
    // TODO: 인앱 배너 등 표시 (flutter_local_notifications 활용 가능)
  }

  void _handleMessageOpenedApp(RemoteMessage message) {
    if (kDebugMode) {
      // ignore: avoid_print
      print('[FCM] 알림 탭: ${message.data}');
    }
    // TODO: data.payload에 따라 화면 이동 (GoRouter)
  }

  /// 로그인/팀 선택 후 토큰 동기화 (uid, teamId 확정 시 호출)
  Future<void> syncTokenToFirestore() async {
    final token = _lastToken ?? await _messaging.getToken();
    if (token != null) await _saveTokenToFirestore(token);
  }

  /// 로그아웃 시 토큰 제거
  Future<void> clearToken(String teamId, String memberId) async {
    try {
      await _ref.read(teamRepositoryProvider).updateMemberFcmToken(
            teamId: teamId,
            memberId: memberId,
            fcmToken: null,
          );
      await _messaging.deleteToken();
    } catch (_) {}
  }
}
