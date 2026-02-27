import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'router/admin_router.dart';

/// 어드민 웹 전용 앱 (웹에서 /admin 경로로 접근 시)
class AdminApp extends ConsumerWidget {
  const AdminApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(adminRouterProvider);

    return MaterialApp.router(
      title: '영원FC 어드민',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue, brightness: Brightness.light),
        useMaterial3: true,
      ),
      routerConfig: router,
    );
  }
}
