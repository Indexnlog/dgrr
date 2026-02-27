import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/widgets/lazy_indexed_stack.dart';
import '../../features/auth/presentation/providers/auth_state_provider.dart';
import '../../features/events/presentation/pages/class_detail_page.dart';
import '../../features/fees/presentation/pages/fee_management_page.dart';
import '../../features/grounds/presentation/pages/ground_management_page.dart';
import '../../features/matches/presentation/pages/home_page.dart';
import '../../features/matches/presentation/pages/match_create_page.dart';
import '../../features/matches/presentation/pages/match_detail_page.dart';
import '../../features/matches/presentation/pages/match_tab_page.dart';
import '../../features/opponents/presentation/pages/opponent_list_page.dart';
import '../../features/mypage/presentation/pages/my_page.dart';
import '../../features/mypage/presentation/pages/privacy_policy_page.dart';
import '../../features/mypage/presentation/pages/terms_page.dart';
import '../../features/teams/presentation/pages/team_settings_page.dart';
import '../../features/onboarding/presentation/pages/pending_approval_page.dart';
import '../../features/onboarding/presentation/pages/team_select_page.dart';
import '../../features/onboarding/presentation/pages/welcome_guide_page.dart';
import '../../features/teams/domain/entities/member.dart';
import '../../features/teams/presentation/providers/current_member_status_provider.dart';
import '../../features/polls/presentation/pages/poll_create_page.dart';
import '../../features/polls/presentation/pages/poll_detail_page.dart';
import '../../features/polls/presentation/pages/poll_list_page.dart';
import '../../features/posts/presentation/pages/post_create_page.dart';
import '../../features/posts/presentation/pages/post_detail_page.dart';
import '../../features/posts/presentation/pages/post_list_page.dart';
import '../../features/reservations/presentation/pages/reservation_notice_create_page.dart';
import '../../features/reservations/presentation/pages/reservation_notice_detail_page.dart';
import '../../features/reservations/presentation/pages/reservation_notice_list_page.dart';
import '../../features/schedule/presentation/pages/schedule_page.dart';
import '../../features/teams/presentation/providers/current_team_provider.dart';
import '../widgets/main_shell.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

/// 앱 라우터 Provider (인증/팀 선택 가드 포함)
final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);
  final currentTeamId = ref.watch(currentTeamIdProvider);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    redirect: (context, state) {
      final isAuthenticated = authState.value != null;
      final hasTeam = currentTeamId != null;
      final currentLocation = state.matchedLocation;

      if (!isAuthenticated && currentLocation != '/' && currentLocation != '/welcome') {
        return '/';
      }

      if (isAuthenticated && !hasTeam && currentLocation != '/' && currentLocation != '/welcome') {
        return '/';
      }

      if (isAuthenticated && hasTeam && currentLocation == '/') {
        return '/home';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        name: 'team-select',
        builder: (context, state) => const TeamSelectPage(),
      ),
      GoRoute(
        path: '/welcome',
        name: 'welcome-guide',
        builder: (context, state) => const WelcomeGuidePage(),
      ),
      StatefulShellRoute(
        builder: (context, state, navigationShell) {
          return Consumer(
            builder: (context, ref, _) {
              final statusAsync = ref.watch(currentMemberStatusInTeamProvider);
              return statusAsync.when(
                data: (status) {
                  if (status == MemberStatus.pending) {
                    return const PendingApprovalPage();
                  }
                  return MainShell(navigationShell: navigationShell);
                },
                loading: () => const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                ),
                error: (_, __) => MainShell(navigationShell: navigationShell),
              );
            },
          );
        },
        navigatorContainerBuilder: (context, navigationShell, children) {
          return LazyIndexedStack(
            navigationShell: navigationShell,
            children: children,
          );
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home',
                name: 'home',
                builder: (context, state) => const HomePage(),
                routes: [
                  GoRoute(
                    path: 'posts',
                    name: 'post-list',
                    builder: (context, state) => const PostListPage(),
                    routes: [
                      GoRoute(
                        path: 'create',
                        name: 'post-create',
                        builder: (context, state) => const PostCreatePage(),
                      ),
                      GoRoute(
                        path: ':postId',
                        name: 'post-detail',
                        builder: (context, state) => PostDetailPage(
                          postId: state.pathParameters['postId']!,
                        ),
                        routes: [
                          GoRoute(
                            path: 'edit',
                            name: 'post-edit',
                            builder: (context, state) => PostCreatePage(
                              postId: state.pathParameters['postId'],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/schedule',
                name: 'schedule',
                builder: (context, state) => const SchedulePage(),
                routes: [
                  GoRoute(
                    path: 'class/:eventId',
                    name: 'class-detail',
                    builder: (context, state) => ClassDetailPage(
                      eventId: state.pathParameters['eventId']!,
                    ),
                  ),
                  GoRoute(
                    path: 'reservation-notices',
                    name: 'reservation-notice-list',
                    builder: (context, state) =>
                        const ReservationNoticeListPage(),
                    routes: [
                      GoRoute(
                        path: 'create',
                        name: 'reservation-notice-create',
                        builder: (context, state) =>
                            const ReservationNoticeCreatePage(),
                      ),
                      GoRoute(
                        path: ':noticeId',
                        name: 'reservation-notice-detail',
                        builder: (context, state) =>
                            ReservationNoticeDetailPage(
                          noticeId: state.pathParameters['noticeId']!,
                        ),
                      ),
                    ],
                  ),
                  GoRoute(
                    path: 'polls',
                    name: 'poll-list',
                    builder: (context, state) => const PollListPage(),
                    routes: [
                      GoRoute(
                        path: 'create',
                        name: 'poll-create',
                        builder: (context, state) =>
                            const PollCreatePage(),
                      ),
                      GoRoute(
                        path: ':pollId',
                        name: 'poll-detail',
                        builder: (context, state) => PollDetailPage(
                          pollId: state.pathParameters['pollId']!,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/match',
                name: 'match',
                builder: (context, state) => const MatchTabPage(),
                routes: [
                  GoRoute(
                    path: 'create',
                    name: 'match-create',
                    builder: (context, state) => const MatchCreatePage(),
                  ),
                  GoRoute(
                    path: 'opponents',
                    name: 'opponent-list',
                    builder: (context, state) => const OpponentListPage(),
                  ),
                  GoRoute(
                    path: ':matchId',
                    name: 'match-detail',
                    builder: (context, state) => MatchDetailPage(
                      matchId: state.pathParameters['matchId']!,
                    ),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/my',
                name: 'my',
                builder: (context, state) => const MyPage(),
                routes: [
                  GoRoute(
                    path: 'fees',
                    name: 'fee-management',
                    builder: (context, state) =>
                        const FeeManagementPage(),
                  ),
                  GoRoute(
                    path: 'grounds',
                    name: 'ground-management',
                    builder: (context, state) =>
                        const GroundManagementPage(),
                  ),
                  GoRoute(
                    path: 'privacy',
                    name: 'privacy-policy',
                    builder: (context, state) => const PrivacyPolicyPage(),
                  ),
                  GoRoute(
                    path: 'terms',
                    name: 'terms',
                    builder: (context, state) => const TermsPage(),
                  ),
                  GoRoute(
                    path: 'team-settings',
                    name: 'team-settings',
                    builder: (context, state) => const TeamSettingsPage(),
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
