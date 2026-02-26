import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/permissions/permission_checker.dart';
import '../../../auth/presentation/providers/auth_state_provider.dart';
import '../../../teams/presentation/providers/current_team_provider.dart';
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

/// 공지 작성/수정 페이지
class PostCreatePage extends ConsumerStatefulWidget {
  const PostCreatePage({super.key, this.postId});

  /// 수정 시 전달
  final String? postId;

  @override
  ConsumerState<PostCreatePage> createState() => _PostCreatePageState();
}

class _PostCreatePageState extends ConsumerState<PostCreatePage> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  bool _isPinned = false;
  bool _isSaving = false;
  bool _hasPopulatedFromPost = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.postId != null;
    final postAsync = isEdit
        ? ref.watch(postDetailProvider(widget.postId!))
        : const AsyncValue.data(null);

    return Scaffold(
      backgroundColor: _DS.bgDeep,
      appBar: AppBar(
        backgroundColor: _DS.bgDeep,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: _DS.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: Text(
          isEdit ? '공지 수정' : '공지 작성',
          style: const TextStyle(
            color: _DS.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          if (isEdit)
            IconButton(
              icon: Icon(Icons.delete_outline, color: _DS.teamRed, size: 22),
              onPressed: _isSaving ? null : _deletePost,
            ),
        ],
      ),
      body: postAsync.when(
        data: (post) {
          if (isEdit && post == null) {
            return const Center(
              child: Text(
                '게시글을 찾을 수 없습니다',
                style: TextStyle(color: _DS.textSecondary),
              ),
            );
          }
          if (post != null && !_hasPopulatedFromPost) {
            _hasPopulatedFromPost = true;
            _titleController.text = post.title;
            _contentController.text = post.content ?? '';
            _isPinned = post.isPinned ?? false;
          }
          return _buildForm(isEdit);
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

  Widget _buildForm(bool isEdit) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _titleController,
            style: const TextStyle(
              color: _DS.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
            decoration: InputDecoration(
              hintText: '제목',
              hintStyle: TextStyle(color: _DS.textMuted, fontSize: 16),
              filled: true,
              fillColor: _DS.bgCard,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: _DS.divider),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: _DS.divider),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: _DS.teamRed, width: 1.5),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _contentController,
            maxLines: 12,
            style: const TextStyle(
              color: _DS.textPrimary,
              fontSize: 15,
              height: 1.5,
            ),
            decoration: InputDecoration(
              hintText: '내용을 입력하세요',
              hintStyle: TextStyle(color: _DS.textMuted, fontSize: 14),
              filled: true,
              fillColor: _DS.bgCard,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: _DS.divider),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: _DS.divider),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: _DS.teamRed, width: 1.5),
              ),
              contentPadding: const EdgeInsets.all(16),
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 20),
          // 상단 고정 토글
          GestureDetector(
            onTap: () => setState(() => _isPinned = !_isPinned),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: _DS.bgCard,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _DS.divider),
              ),
              child: Row(
                children: [
                  Icon(
                    _isPinned ? Icons.push_pin : Icons.push_pin_outlined,
                    color: _isPinned ? _DS.attendGreen : _DS.textMuted,
                    size: 22,
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    '상단 고정',
                    style: TextStyle(
                      color: _DS.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  Switch(
                    value: _isPinned,
                    onChanged: (v) => setState(() => _isPinned = v),
                    activeColor: _DS.attendGreen,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isSaving ? null : () => _save(isEdit),
              style: ElevatedButton.styleFrom(
                backgroundColor: _DS.teamRed,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: _isSaving
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(isEdit ? '수정 완료' : '등록하기'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _save(bool isEdit) async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('제목을 입력하세요')),
      );
      return;
    }

    final uid = ref.read(currentUserProvider)?.uid;
    final teamId = ref.read(currentTeamIdProvider);
    if (uid == null || teamId == null) return;

    if (!PermissionChecker.isAdmin(ref) && !PermissionChecker.isCoach(ref)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('권한이 없습니다')),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      final ds = ref.read(postDataSourceProvider);
      if (isEdit && widget.postId != null) {
        final content = _contentController.text.trim();
        await ds.updatePost(teamId, widget.postId!, {
          'title': title,
          'content': content.isEmpty ? '' : content,
          'isPinned': _isPinned,
          'updatedAt': FieldValue.serverTimestamp(),
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('수정되었습니다')),
          );
          context.pop();
        }
      } else {
        final post = PostModel(
          postId: '',
          title: title,
          content: _contentController.text.trim().isEmpty
              ? null
              : _contentController.text.trim(),
          category: '공지',
          authorId: uid,
          isPinned: _isPinned,
          createdAt: DateTime.now(),
        );
        await ds.createPost(teamId, post);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('등록되었습니다')),
          );
          context.pop();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('오류: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _deletePost() async {
    final teamId = ref.read(currentTeamIdProvider);
    if (teamId == null || widget.postId == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _DS.bgCard,
        title: const Text(
          '공지 삭제',
          style: TextStyle(color: _DS.textPrimary),
        ),
        content: const Text(
          '이 공지를 삭제하시겠습니까?',
          style: TextStyle(color: _DS.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('취소', style: TextStyle(color: _DS.textMuted)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('삭제', style: TextStyle(color: _DS.teamRed)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isSaving = true);
    try {
      await ref.read(postDataSourceProvider).deletePost(teamId, widget.postId!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('삭제되었습니다')),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('오류: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}
