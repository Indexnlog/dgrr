import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../presentation/pages/admin_login_page.dart';
import '../presentation/pages/admin_shell_page.dart';
import '../presentation/pages/team_create_page.dart';
import '../presentation/pages/team_edit_page.dart';
import '../presentation/pages/team_list_page.dart';
import '../presentation/pages/team_members_page.dart';

final _shellNavigatorKey = GlobalKey<NavigatorState>();

/// 어드민 웹 라우터
/// - 비로그인 시 무조건 /admin/login 먼저 표시
/// - 로그인 후 /admin → /admin/teams
final adminRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: _shellNavigatorKey,
    initialLocation: '/admin/login',
    routes: [
      GoRoute(
        path: '/admin',
        redirect: (_, state) {
          // state.matchedLocation은 부모 경로까지만 반환하므로
          // 전체 이동 경로는 state.uri.path로 확인
          final loc = state.uri.path;
          // 로그인 페이지는 그대로
          if (loc == '/admin/login') return null;
          // 비로그인 시 무조건 로그인 화면으로
          if (FirebaseAuth.instance.currentUser == null) {
            return '/admin/login';
          }
          // 로그인됐을 때 /admin 루트만 오면 팀 목록으로
          if (loc == '/admin') return '/admin/teams';
          return null;
        },
        routes: [
          GoRoute(
            path: 'login',
            builder: (_, __) => const AdminLoginPage(),
          ),
          ShellRoute(
            builder: (_, state, child) => AdminShellPage(
              currentPath: state.uri.path,
              child: child,
            ),
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
                    path: ':teamId/edit',
                    pageBuilder: (_, state) => NoTransitionPage(
                      child: TeamEditPage(
                        teamId: state.pathParameters['teamId']!,
                      ),
                    ),
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
