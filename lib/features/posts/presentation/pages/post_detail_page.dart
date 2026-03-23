import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/errors/error_handler.dart';
import '../../../../core/permissions/permission_checker.dart';
import '../../../../core/widgets/error_retry_view.dart';
import '../providers/post_providers.dart';

class _DS {
  _DS._();
  static const bgDeep = Color(0xFF0D1117);
  static const bgCard = Color(0xFF161B22);
  static const teamRed = Color(0xFFDC2626);
  static const textPrimary = Color(0xFFF0F6FC);
  static const textSecondary = Color(0xFF8B949E);
  static const attendGreen = Color(0xFF2EA043);
  static const divider = Color(0xFF30363D);
}

/// 공지 상세 페이지 (읽기 전용)
class PostDetailPage extends ConsumerWidget {
  const PostDetailPage({super.key, required this.postId});
  final String postId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final postAsync = ref.watch(postDetailProvider(postId));
    final canManage =
        PermissionChecker.isAdmin(ref) || PermissionChecker.isCoach(ref);

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
              icon: const Icon(Icons.edit_outlined, color: _DS.textPrimary),
              onPressed: () async {
                await context.push('/home/posts/$postId/edit');
                ref.invalidate(postDetailProvider(postId));
              },
              tooltip: '수정',
            ),
        ],
      ),
      body: postAsync.when(
        data: (post) {
          if (post == null) {
            return const Center(
              child: Text(
                '게시글을 찾을 수 없습니다',
                style: TextStyle(color: _DS.textSecondary),
              ),
            );
          }
          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (post.isPinned == true)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      children: [
                        Icon(Icons.push_pin, color: _DS.attendGreen, size: 18),
                        const SizedBox(width: 6),
                        Text(
                          '상단 고정',
                          style: TextStyle(
                            color: _DS.attendGreen,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                Text(
                  post.title,
                  style: const TextStyle(
                    color: _DS.textPrimary,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    if ((post.category ?? '').isNotEmpty) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: _DS.teamRed.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          post.category!,
                          style: const TextStyle(
                            color: _DS.teamRed,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    Expanded(
                      child: Text(
                        _formatPostDate(post.createdAt),
                        style: TextStyle(
                          color: _DS.textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                if (post.content != null && post.content!.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: _DS.bgCard,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: _DS.divider),
                    ),
                    child: Text(
                      post.content!,
                      style: const TextStyle(
                        color: _DS.textPrimary,
                        fontSize: 15,
                        height: 1.6,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(
            color: _DS.teamRed,
            strokeWidth: 2.5,
          ),
        ),
        error: (e, _) => ErrorRetryView(
          message: ErrorHandler.toUserMessage(e, fallback: '공지를 불러오지 못했습니다'),
          detail: e.toString(),
          onRetry: () => ref.invalidate(postDetailProvider(postId)),
        ),
      ),
    );
  }
}

String _formatPostDate(DateTime? dt) {
  if (dt == null) return '작성일 미상';
  return DateFormat('yyyy.MM.dd HH:mm', 'ko_KR').format(dt);
}
