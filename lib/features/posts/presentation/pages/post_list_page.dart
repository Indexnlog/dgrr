import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/permissions/permission_checker.dart';
import '../../data/models/post_model.dart';
import '../providers/post_providers.dart';

class _DS {
  _DS._();
  static const bgDeep = Color(0xFF0D1117);
  static const bgCard = Color(0xFF161B22);
  static const teamRed = Color(0xFFDC2626);
  static const textPrimary = Color(0xFFF0F6FC);
  static const textSecondary = Color(0xFF8B949E);
  static const textMuted = Color(0xFF484F58);
  static const attendGreen = Color(0xFF2EA043);
  static const divider = Color(0xFF30363D);
}

/// 공지 목록 페이지
class PostListPage extends ConsumerWidget {
  const PostListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final postsAsync = ref.watch(recentPostsProvider);
    final canManage = PermissionChecker.isAdmin(ref) || PermissionChecker.isCoach(ref);

    return Scaffold(
      backgroundColor: _DS.bgDeep,
      appBar: AppBar(
        backgroundColor: _DS.bgDeep,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: _DS.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          '공지',
          style: TextStyle(
            color: _DS.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          if (canManage)
            IconButton(
              icon: const Icon(Icons.add, color: _DS.textPrimary),
              onPressed: () => context.push('/home/posts/create'),
              tooltip: '공지 작성',
            ),
        ],
      ),
      body: postsAsync.when(
        data: (posts) {
          if (posts.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.campaign_outlined, color: _DS.textMuted, size: 48),
                  const SizedBox(height: 12),
                  Text(
                    '등록된 공지가 없습니다',
                    style: TextStyle(color: _DS.textSecondary, fontSize: 15),
                  ),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
            itemCount: posts.length,
            itemBuilder: (context, index) {
              final post = posts[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _PostCard(post: post),
              );
            },
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(
            color: _DS.teamRed,
            strokeWidth: 2.5,
          ),
        ),
        error: (e, _) => Center(
          child: Text(
            '오류: $e',
            style: const TextStyle(color: _DS.textSecondary),
          ),
        ),
      ),
    );
  }
}

class _PostCard extends ConsumerWidget {
  const _PostCard({required this.post});
  final PostModel post;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () => context.push('/home/posts/${post.postId}'),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _DS.bgCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _DS.divider),
        ),
        child: Row(
          children: [
            if (post.isPinned == true)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Icon(Icons.push_pin, color: _DS.attendGreen, size: 16),
              ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    post.title,
                    style: const TextStyle(
                      color: _DS.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (post.content != null && post.content!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      post.content!,
                      style: TextStyle(
                        color: _DS.textMuted,
                        fontSize: 13,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: _DS.textMuted, size: 20),
          ],
        ),
      ),
    );
  }
}
