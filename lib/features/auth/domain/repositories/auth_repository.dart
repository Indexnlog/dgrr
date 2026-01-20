import 'package:firebase_auth/firebase_auth.dart';

class AuthCanceledException implements Exception {
  const AuthCanceledException();
}

abstract class AuthRepository {
  Future<UserCredential> signInWithGoogle();
}
