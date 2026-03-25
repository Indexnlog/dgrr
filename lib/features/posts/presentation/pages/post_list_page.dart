import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/errors/error_handler.dart';
import '../../../../core/permissions/permission_checker.dart';
import '../../../../core/widgets/cute_empty_state.dart';
import '../../../../core/widgets/error_retry_view.dart';
import '../../data/models/post_model.dart';
import '../../../teams/presentation/providers/current_team_provider.dart';
import '../providers/post_providers.dart';

class _DS {
  _DS._();
  static const bgDeep = Color(0xFF0D1117);
  static const bgCard = Color(0xFF161B22);
  static const teamRed = Color(0xFFDC2626);
  static const textPrimary = Color(0xFFF0F6FC);
  static const textMuted = Color(0xFF484F58);
  static const attendGreen = Color(0xFF2EA043);
  static const divider = Color(0xFF30363D);
}

/// 공지 목록 페이지
class PostListPage extends ConsumerStatefulWidget {
  const PostListPage({super.key});

  @override
  ConsumerState<PostListPage> createState() => _PostListPageState();
}

class _PostListPageState extends ConsumerState<PostListPage> {
  final TextEditingController _searchController = TextEditingController();
  final List<PostModel> _posts = [];
  final Set<String> _postIds = {};
  QueryDocumentSnapshot<Map<String, dynamic>>? _lastDoc;
  bool _isInitialLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  String? _errorMessage;
  String? _errorDetail;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitial();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadInitial() async {
    final teamId = ref.read(currentTeamIdProvider);
    if (teamId == null) {
      setState(() {
        _isInitialLoading = false;
        _errorMessage = '팀 정보가 없습니다';
        _errorDetail = null;
      });
      return;
    }

    setState(() {
      _isInitialLoading = true;
      _errorMessage = null;
      _errorDetail = null;
      _posts.clear();
      _postIds.clear();
      _lastDoc = null;
      _hasMore = true;
    });

    try {
      final result = await ref
          .read(postDataSourceProvider)
          .fetchNoticePostsPage(teamId, limit: 20);
      if (!mounted) return;
      setState(() {
        _posts.clear();
        _postIds.clear();
        for (final post in result.posts) {
          if (_postIds.add(post.postId)) {
            _posts.add(post);
          }
        }
        _sortPosts();
        _lastDoc = result.lastDoc;
        _hasMore = result.hasMore;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = ErrorHandler.toUserMessage(
          e,
          fallback: '공지를 불러오지 못했습니다',
        );
        _errorDetail = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isInitialLoading = false;
        });
      }
    }
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore || !_hasMore || _lastDoc == null) return;
    final teamId = ref.read(currentTeamIdProvider);
    if (teamId == null) return;

    setState(() {
      _isLoadingMore = true;
    });
    try {
      final result = await ref
          .read(postDataSourceProvider)
          .fetchNoticePostsPage(teamId, startAfter: _lastDoc, limit: 20);
      if (!mounted) return;
      setState(() {
        for (final post in result.posts) {
          if (_postIds.add(post.postId)) {
            _posts.add(post);
          }
        }
        _sortPosts();
        _lastDoc = result.lastDoc;
        _hasMore = result.hasMore && result.posts.isNotEmpty;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingMore = false;
        });
      }
    }
  }

  void _sortPosts() {
    _posts.sort((a, b) {
      final pinnedCompare = (b.isPinned == true ? 1 : 0).compareTo(
        a.isPinned == true ? 1 : 0,
      );
      if (pinnedCompare != 0) {
        return pinnedCompare;
      }

      final aTime = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bTime = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bTime.compareTo(aTime);
    });
  }

  @override
  Widget build(BuildContext context) {
    final canManage =
        PermissionChecker.isAdmin(ref) || PermissionChecker.isCoach(ref);
    final filteredPosts = _searchQuery.isEmpty
        ? _posts
        : _posts.where((post) {
            final title = post.title.toLowerCase();
            final content = (post.content ?? '').toLowerCase();
            return title.contains(_searchQuery) ||
                content.contains(_searchQuery);
          }).toList();

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
              onPressed: () async {
                await context.push('/home/posts/create');
                if (mounted) {
                  _loadInitial();
                }
              },
              tooltip: '공지 작성',
            ),
        ],
      ),
      body: _isInitialLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: _DS.teamRed,
                strokeWidth: 2.5,
              ),
            )
          : _errorMessage != null
          ? ErrorRetryView(
              message: _errorMessage!,
              detail: _errorDetail,
              onRetry: _loadInitial,
            )
          : RefreshIndicator(
              onRefresh: _loadInitial,
              child: ListView.builder(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                itemCount:
                    (filteredPosts.isEmpty ? 1 : filteredPosts.length) +
                    ((_isLoadingMore || (!_hasMore && filteredPosts.isNotEmpty))
                        ? 1
                        : 0),
                itemBuilder: (context, index) {
                  if (index == 0) {
                    final searchWidget = Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: TextField(
                        controller: _searchController,
                        onChanged: (value) {
                          setState(() {
                            _searchQuery = value.trim().toLowerCase();
                          });
                        },
                        decoration: InputDecoration(
                          hintText: '공지 제목/내용 검색',
                          hintStyle: TextStyle(
                            color: _DS.textMuted,
                            fontSize: 13,
                          ),
                          prefixIcon: Icon(
                            Icons.search,
                            color: _DS.textMuted,
                            size: 20,
                          ),
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
                            borderSide: const BorderSide(
                              color: _DS.teamRed,
                              width: 1.4,
                            ),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                        ),
                        style: const TextStyle(
                          color: _DS.textPrimary,
                          fontSize: 14,
                        ),
                      ),
                    );

                    if (filteredPosts.isNotEmpty) {
                      return searchWidget;
                    }

                    return Column(
                      children: [
                        searchWidget,
                        Padding(
                          padding: const EdgeInsets.only(top: 24),
                          child: CuteEmptyState(
                            title: _posts.isEmpty
                                ? '등록된 공지가 없어요'
                                : '검색 결과가 없어요',
                            subtitle: _posts.isEmpty
                                ? '첫 공지를 작성해서 팀에게 공유해보세요.'
                                : '검색어를 바꿔서 다시 찾아보세요.',
                            icon: _posts.isEmpty
                                ? Icons.campaign_outlined
                                : Icons.search_off_rounded,
                            accentColor: _DS.teamRed,
                          ),
                        ),
                      ],
                    );
                  }

                  final listIndex = index - 1;
                  if (listIndex >= filteredPosts.length) {
                    if (_isLoadingMore) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Center(
                          child: CircularProgressIndicator(
                            color: _DS.teamRed,
                            strokeWidth: 2,
                          ),
                        ),
                      );
                    }
                    if (!_hasMore && filteredPosts.isNotEmpty) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Center(
                          child: Text(
                            '모든 공지를 확인했어요',
                            style: TextStyle(
                              color: _DS.textMuted,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      );
                    }
                  }

                  if (listIndex == filteredPosts.length - 1 && _hasMore) {
                    _loadMore();
                  }

                  final post = filteredPosts[listIndex];
                  return Padding(
                    padding: EdgeInsets.only(
                      bottom: listIndex == filteredPosts.length - 1 ? 0 : 12,
                    ),
                    child: _PostCard(post: post, onOpened: _loadInitial),
                  );
                },
              ),
            ),
    );
  }
}

class _PostCard extends ConsumerWidget {
  const _PostCard({required this.post, required this.onOpened});
  final PostModel post;
  final Future<void> Function() onOpened;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () async {
        await context.push('/home/posts/${post.postId}');
        await onOpened();
      },
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
                      style: TextStyle(color: _DS.textMuted, fontSize: 13),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      if ((post.category ?? '').isNotEmpty) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: _DS.teamRed.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            post.category!,
                            style: const TextStyle(
                              color: _DS.teamRed,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                      ],
                      Expanded(
                        child: Text(
                          _formatPostDate(post.createdAt),
                          style: TextStyle(
                            color: _DS.textMuted,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
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

String _formatPostDate(DateTime? dt) {
  if (dt == null) return '작성일 미상';
  return DateFormat('yyyy.MM.dd HH:mm', 'ko_KR').format(dt);
}
