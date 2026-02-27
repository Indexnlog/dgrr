import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/firebase_ready_provider.dart';
import '../../features/notifications/presentation/providers/fcm_provider.dart';

/// FCM 초기화 위젯 (앱 시작 시 권한 요청, 토큰 획득)
class FcmInitializer extends ConsumerStatefulWidget {
  const FcmInitializer({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<FcmInitializer> createState() => _FcmInitializerState();
}

class _FcmInitializerState extends ConsumerState<FcmInitializer> {
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!ref.read(firebaseReadyProvider) || _initialized) return;
    _initialized = true;
    ref.read(fcmProvider).initialize();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
