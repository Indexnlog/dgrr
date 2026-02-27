import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'router/app_router.dart';
import 'widgets/fcm_initializer.dart';

class DgrrApp extends ConsumerWidget {
  const DgrrApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    return FcmInitializer(
      child: MaterialApp.router(
        title: '영원FC',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
          useMaterial3: true,
        ),
        routerConfig: router,
      ),
    );
  }
}
