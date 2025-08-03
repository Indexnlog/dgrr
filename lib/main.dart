import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'firebase_options.dart';
import 'providers/team_provider.dart';
import 'providers/user_role_provider.dart';

import 'pages/main_page.dart';
import 'pages/auth/login_page.dart';
import 'pages/auth/select_team_page.dart';
import 'pages/auth/init_page.dart'; // ✅ 추가
import 'pages/auth/splash_page.dart'; // ✅ 추가

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  final prefs = await SharedPreferences.getInstance();
  final savedTeamId = prefs.getString('selectedTeamId');

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) {
            final teamProvider = TeamProvider();
            if (savedTeamId != null) {
              teamProvider.setTeamId(savedTeamId);
            }
            return teamProvider;
          },
        ),
        ChangeNotifierProvider(create: (_) => UserRoleProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '지구공',
      debugShowCheckedModeBanner: false,
      home: const SplashPage(), // ✅ 최초 진입점 변경!
    );
  }
}
