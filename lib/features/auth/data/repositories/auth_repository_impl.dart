import 'package:firebase_auth/firebase_auth.dart';

import '../../domain/repositories/auth_repository.dart';
import '../datasources/google_auth_data_source.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(this.googleAuthDataSource);

  final GoogleAuthDataSource googleAuthDataSource;

  @override
  Future<UserCredential> signInWithGoogle() {
    return googleAuthDataSource.signInWithGoogle();
  }
}
