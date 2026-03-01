import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_typography.dart';
import '../admin/admin_app.dart';
import 'router/app_router.dart';
import 'widgets/fcm_initializer.dart';

class DgrrApp extends ConsumerWidget {
  const DgrrApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 웹에서 /admin 경로면 어드민 앱 표시
    if (kIsWeb && _isAdminPath()) {
      return const AdminApp();
    }

    final router = ref.watch(appRouterProvider);

    return FcmInitializer(
      child: MaterialApp.router(
        title: '영원FC',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF2853E5),
            brightness: Brightness.light,
          ),
          useMaterial3: true,
          fontFamily: GoogleFonts.notoSansKr().fontFamily,
          textTheme: AppTypography.textTheme,
        ),
        themeMode: ThemeMode.light,
        routerConfig: router,
      ),
    );
  }

  bool _isAdminPath() {
    // path 기반(/admin) 또는 hash 기반(/#/admin) 모두 지원
    final path = Uri.base.path;
    final fragment = Uri.base.fragment;
    return path.startsWith('/admin') ||
        fragment.startsWith('/admin') ||
        fragment == 'admin';
  }
}
