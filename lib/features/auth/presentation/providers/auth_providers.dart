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
  
  // Google Sign-In 7.x는 initialize 시 clientId가 필요할 수 있지만,
  // Firebase Auth와 함께 사용할 때는 보통 생략 가능합니다.
  // 필요시 Firebase Console에서 iOS Client ID를 확인하여 추가하세요.
  final dataSource = GoogleAuthDataSource(
    auth: auth,
    googleSignIn: googleSignIn,
    iosClientId: null, // 필요시 추가
    serverClientId: null, // 필요시 추가
  );
  return AuthRepositoryImpl(dataSource);
});

final signInWithGoogleProvider = Provider<SignInWithGoogle>((ref) {
  return SignInWithGoogle(ref.watch(authRepositoryProvider));
});

/// 에뮬레이터 전용 익명 로그인 Provider
final signInAnonymouslyProvider = Provider<Future<UserCredential> Function()>((ref) {
  final repo = ref.watch(authRepositoryProvider);
  return () => repo.signInAnonymously();
});

/// 로그아웃 Provider
final signOutProvider = Provider<void Function()>((ref) {
  final auth = FirebaseAuth.instance;
  final googleSignIn = GoogleSignIn.instance;
  
  return () async {
    await Future.wait([
      auth.signOut(),
      googleSignIn.signOut(),
    ]);
  };
});
