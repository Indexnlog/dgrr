import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/providers/firebase_ready_provider.dart';

/// 인증 상태 Stream Provider
/// Firebase 미초기화 시 빈 스트림 반환 (앱 크래시 방지)
final authStateProvider = StreamProvider<User?>((ref) {
  if (!ref.watch(firebaseReadyProvider)) {
    return Stream.value(null);
  }
  return FirebaseAuth.instance.authStateChanges();
});

/// 현재 로그인한 사용자 Provider
final currentUserProvider = Provider<User?>((ref) {
  return ref.watch(authStateProvider).value;
});

/// 로그인 여부 Provider
final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(currentUserProvider) != null;
});
