import 'package:firebase_auth/firebase_auth.dart';

import '../repositories/auth_repository.dart';

class SignInWithGoogle {
  SignInWithGoogle(this.repository);

  final AuthRepository repository;

  Future<UserCredential> call() {
    return repository.signInWithGoogle();
  }
}
