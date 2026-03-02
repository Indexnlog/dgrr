import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../domain/repositories/auth_repository.dart';

class GoogleAuthDataSource {
  GoogleAuthDataSource({
    required this.auth,
    required this.googleSignIn,
    this.iosClientId,
    this.serverClientId,
  });

  final FirebaseAuth auth;
  final GoogleSignIn googleSignIn;
  final String? iosClientId;
  final String? serverClientId;
  bool _isInitialized = false;

  Future<void> _ensureInitialized() async {
    if (_isInitialized) {
      return;
    }
    await googleSignIn.initialize(
      clientId: iosClientId,
      serverClientId: serverClientId,
    );
    _isInitialized = true;
  }

  Future<UserCredential> signInWithGoogle() async {
    try {
      // 웹: google_sign_in FedCM 이슈 → Firebase Auth signInWithPopup 직접 사용
      if (kIsWeb) {
        print('[GoogleAuth] 웹 - signInWithPopup 시도...');
        final provider = GoogleAuthProvider()
          ..addScope('email')
          ..addScope('profile');
        final result = await auth.signInWithPopup(provider);
        print('[GoogleAuth] 웹 - signInWithPopup 성공: ${result.user?.uid}');
        return result;
      }

      // 모바일: google_sign_in 패키지 사용
      print('[GoogleAuth] 1. 초기화 시작...');
      await _ensureInitialized();
      print('[GoogleAuth] 1. 초기화 완료');

      // 1) 조용한 재로그인 시도 (캐시된 세션)
      GoogleSignInAccount? googleUser;
      try {
        print('[GoogleAuth] 2. Silent sign-in 시도...');
        googleUser = await googleSignIn.attemptLightweightAuthentication();
        print('[GoogleAuth] 2. Silent sign-in 결과: ${googleUser != null ? "성공" : "null(캐시 없음)"}');
      } catch (e) {
        print('[GoogleAuth] 2. Silent sign-in 예외: $e');
      }

      // 2) 캐시 없으면 사용자에게 Google 팝업 표시
      if (googleUser == null) {
        print('[GoogleAuth] 3. 사용자 인증 UI 표시...');
        googleUser = await googleSignIn.authenticate();
        print('[GoogleAuth] 3. 사용자 인증 완료');
      }

      print('[GoogleAuth] 4. 인증 정보 가져오기...');
      final googleAuth = googleUser.authentication;
      print('[GoogleAuth] 4. idToken=${googleAuth.idToken != null ? "있음" : "없음"}');

      if (googleAuth.idToken == null) {
        throw Exception('idToken이 없습니다. Google Sign-In 설정을 확인해주세요.');
      }

      print('[GoogleAuth] 5. Firebase 로그인 시도...');
      final credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );
      final result = await auth.signInWithCredential(credential);
      print('[GoogleAuth] 5. Firebase 로그인 성공: ${result.user?.uid}');
      return result;
    } catch (e, stackTrace) {
      if (e is AuthCanceledException) {
        print('[GoogleAuth] 사용자가 취소함');
        rethrow;
      }
      // Firebase Auth의 popup 취소는 별도 코드로 옴
      if (e is FirebaseAuthException && e.code == 'popup-closed-by-user') {
        throw const AuthCanceledException();
      }
      print('[GoogleAuth] 에러: ${e.runtimeType} - $e');
      print('[GoogleAuth] 스택: $stackTrace');
      rethrow;
    }
  }
}
