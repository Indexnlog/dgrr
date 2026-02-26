import 'package:firebase_auth/firebase_auth.dart';
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
      print('[GoogleAuth] 1. 초기화 시작...');
      await _ensureInitialized();
      print('[GoogleAuth] 1. 초기화 완료');

      GoogleSignInAccount? googleUser;
      try {
        print('[GoogleAuth] 2. Silent sign-in 시도...');
        googleUser = await googleSignIn.attemptLightweightAuthentication();
        print('[GoogleAuth] 2. Silent sign-in 성공');
      } catch (e) {
        print('[GoogleAuth] 2. Silent sign-in 실패: $e');
        print('[GoogleAuth] 3. 사용자 인증 UI 표시...');
        googleUser = await googleSignIn.authenticate();
        print('[GoogleAuth] 3. 사용자 인증 완료');
      }

      if (googleUser == null) {
        print('[GoogleAuth] 사용자가 취소함');
        throw const AuthCanceledException();
      }

      print('[GoogleAuth] 4. 인증 정보 가져오기...');
      // google_sign_in 7.x: idToken만 GoogleSignInAuthentication에 존재
      final googleAuth = googleUser.authentication;
      print('[GoogleAuth] 4. 인증 정보: idToken=${googleAuth.idToken != null ? "있음" : "없음"}');

      if (googleAuth.idToken == null) {
        throw Exception('idToken이 없습니다. Google Sign-In 설정을 확인해주세요.');
      }

      // Firebase Auth는 idToken만으로 로그인 가능
      print('[GoogleAuth] 5. Firebase Credential 생성...');
      final credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );

      print('[GoogleAuth] 6. Firebase에 로그인 시도...');
      final result = await auth.signInWithCredential(credential);
      print('[GoogleAuth] 6. Firebase 로그인 성공: ${result.user?.uid}');
      return result;
    } catch (e, stackTrace) {
      if (e is AuthCanceledException) {
        print('[GoogleAuth] 사용자가 취소함');
        rethrow;
      }
      print('[GoogleAuth] 에러 발생!');
      print('[GoogleAuth] 타입: ${e.runtimeType}');
      print('[GoogleAuth] 메시지: $e');
      print('[GoogleAuth] 스택: $stackTrace');
      rethrow;
    }
  }
}
