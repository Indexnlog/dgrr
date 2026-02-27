import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../presentation/pages/admin_login_page.dart';
import '../presentation/pages/admin_shell_page.dart';
import '../presentation/pages/team_create_page.dart';
import '../presentation/pages/team_list_page.dart';
import '../presentation/pages/team_members_page.dart';

final _shellNavigatorKey = GlobalKey<NavigatorState>();

/// 어드민 웹 라우터
final adminRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: _shellNavigatorKey,
    initialLocation: '/admin/teams',
    routes: [
      GoRoute(
        path: '/admin',
        redirect: (_, state) =>
            state.matchedLocation == '/admin' ? '/admin/teams' : null,
        routes: [
          GoRoute(
            path: 'login',
            builder: (_, __) => const AdminLoginPage(),
          ),
          ShellRoute(
            builder: (_, __, child) => AdminShellPage(child: child),
            routes: [
              GoRoute(
                path: 'teams',
                pageBuilder: (_, __) =>
                    const NoTransitionPage(child: TeamListPage()),
                routes: [
                  GoRoute(
                    path: 'create',
                    pageBuilder: (_, __) =>
                        const NoTransitionPage(child: TeamCreatePage()),
                  ),
                  GoRoute(
                    path: ':teamId/members',
                    pageBuilder: (_, state) => NoTransitionPage(
                      child: TeamMembersPage(
                        teamId: state.pathParameters['teamId']!,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ],
  );
});
