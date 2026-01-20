import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../domain/repositories/auth_repository.dart';

class GoogleAuthDataSource {
  GoogleAuthDataSource({
    required this.auth,
    required this.googleSignIn,
  });

  final FirebaseAuth auth;
  final GoogleSignIn googleSignIn;
  bool _isInitialized = false;

  Future<void> _ensureInitialized() async {
    if (_isInitialized) {
      return;
    }
    // GoogleSignIn 7.x는 initialize를 먼저 호출해야 합니다.
    await googleSignIn.initialize();
    _isInitialized = true;
  }

  Future<UserCredential> signInWithGoogle() async {
    await _ensureInitialized();

    final googleUser = await googleSignIn.authenticate();
    if (googleUser == null) {
      throw const AuthCanceledException();
    }

    final googleAuth = googleUser.authentication;
    final authz = await googleUser.authorizationClient
        .authorizationForScopes(const ['email']);
    final credential = GoogleAuthProvider.credential(
      accessToken: authz?.accessToken,
      idToken: googleAuth.idToken,
    );

    return auth.signInWithCredential(credential);
  }
}
