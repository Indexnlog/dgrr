import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../data/datasources/google_auth_data_source.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/usecases/sign_in_with_google.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final auth = FirebaseAuth.instance;
  final googleSignIn = GoogleSignIn.instance;
  final dataSource = GoogleAuthDataSource(
    auth: auth,
    googleSignIn: googleSignIn,
  );
  return AuthRepositoryImpl(dataSource);
});

final signInWithGoogleProvider = Provider<SignInWithGoogle>((ref) {
  return SignInWithGoogle(ref.watch(authRepositoryProvider));
});
