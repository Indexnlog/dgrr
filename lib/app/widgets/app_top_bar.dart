import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../core/theme/app_theme.dart';
import '../../features/auth/presentation/providers/auth_state_provider.dart';
import '../../features/polls/presentation/providers/poll_providers.dart';

/// 상단 프로필 및 알람 창 (레퍼런스: Electric blue 헤더)
class AppTopBar extends ConsumerWidget {
  const AppTopBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final activePolls = ref.watch(activePollsProvider).value ?? [];
    final noticeCount = activePolls.length;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: AppTheme.primaryBlue,
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            const Spacer(),
            // 알람(벨) 아이콘
            GestureDetector(
              onTap: () => context.push('/schedule/polls'),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      PhosphorIconsRegular.bell,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                  if (noticeCount > 0)
                    Positioned(
                      top: -2,
                      right: -2,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: AppTheme.accentLime,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 18,
                          minHeight: 18,
                        ),
                        child: Text(
                          noticeCount > 9 ? '9+' : '$noticeCount',
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            // 프로필 아바타
            GestureDetector(
              onTap: () => context.go('/my'),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: user?.photoURL != null
                      ? Colors.transparent
                      : Colors.white.withValues(alpha: 0.3),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.6),
                    width: 2,
                  ),
                ),
                clipBehavior: Clip.antiAlias,
                child: user?.photoURL != null
                    ? Image.network(
                        user!.photoURL!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _buildInitialAvatar(user),
                      )
                    : _buildInitialAvatar(user),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInitialAvatar(dynamic user) {
    final initial = (user?.displayName?.isNotEmpty == true)
        ? user!.displayName!.substring(0, 1).toUpperCase()
        : '?';
    return Center(
      child: Text(
        initial,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
