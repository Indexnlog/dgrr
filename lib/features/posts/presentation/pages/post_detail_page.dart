import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/permissions/permission_checker.dart';
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
              icon: const Icon(Icons.edit_outlined, color: _DS.textPrimary),
              onPressed: () => context.push('/home/posts/$postId/edit'),
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
            padding: const EdgeInsets.all(20),
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
