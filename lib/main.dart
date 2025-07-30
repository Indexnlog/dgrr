import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'firebase_options.dart';
import 'providers/team_provider.dart';
import 'pages/auth/login_page.dart';
import 'pages/auth/select_team_page.dart';
import 'pages/main_page.dart';

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
      ],
      child: MyApp(initialRoute: savedTeamId == null ? 'select' : 'login'),
    ),
  );
}

class MyApp extends StatelessWidget {
  final String initialRoute;
  const MyApp({super.key, required this.initialRoute});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '지구공',
      debugShowCheckedModeBanner: false,
      initialRoute: initialRoute,
      routes: {
        'select': (_) => const SelectTeamPage(),
        'login': (_) => const LoginPage(),
        'main': (_) => const MainPage(),
      },
    );
  }
}
