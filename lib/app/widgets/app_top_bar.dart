import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../features/auth/presentation/providers/auth_state_provider.dart';

/// 상단바: 로고 + 프로필 아바타 (레퍼런스: Electric blue 헤더)
class AppTopBar extends ConsumerWidget {
  const AppTopBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);

    // 상태바 높이만 적용 (시스템 아이콘과 겹치지 않도록)
    final topPadding = MediaQuery.of(context).padding.top;

    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: topPadding + 8,
        bottom: 10,
      ),
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
        top: false,
        bottom: false,
        child: Row(
          children: [
            // 왼쪽: FRFC 로고
            Image.asset(
              'assets/images/logo_frfc.png',
              height: 32,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => Text(
                '영원FC',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const Spacer(),
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
                    ? CachedNetworkImage(
                        imageUrl: user!.photoURL!,
                        fit: BoxFit.cover,
                        errorWidget: (_, __, ___) => _buildInitialAvatar(user),
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
