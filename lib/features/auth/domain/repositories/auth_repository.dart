import 'package:firebase_auth/firebase_auth.dart';

class AuthCanceledException implements Exception {
  const AuthCanceledException();
}

abstract class AuthRepository {
  Future<UserCredential> signInWithGoogle();

  /// 에뮬레이터 테스트 전용 익명 로그인
  Future<UserCredential> signInAnonymously();
}
