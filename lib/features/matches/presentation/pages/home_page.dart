import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../core/theme/app_theme.dart';

import '../../../auth/presentation/providers/auth_state_provider.dart';
import '../../../../core/permissions/permission_checker.dart';
import '../../../polls/presentation/providers/poll_providers.dart';
import '../../../posts/data/models/post_model.dart';
import '../../../posts/presentation/providers/post_providers.dart';
import '../../../reservations/data/models/reservation_notice_model.dart';
import '../../../reservations/domain/entities/reservation_notice.dart';
import '../../../reservations/presentation/providers/reservation_notice_providers.dart';
import '../../../teams/domain/entities/member.dart';
import '../../../teams/presentation/providers/team_members_provider.dart';
import '../../domain/entities/match.dart';
import '../providers/match_providers.dart';


class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage>
    with SingleTickerProviderStateMixin {
  bool _seeded = false;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!_seeded) {
        _seeded = true;
        await seedSampleMatch(ref);
      }
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final matchesAsync = ref.watch(upcomingMatchesProvider);
    final currentUser = ref.watch(currentUserProvider);
    final allMembers = ref.watch(teamMembersProvider).value ?? [];
    final activePolls = ref.watch(activePollsProvider).value ?? [];
    final recentPosts = ref.watch(recentPostsProvider).value ?? [];
    final upcomingNotices = ref.watch(upcomingReservationNoticesProvider).value ?? [];

    return Scaffold(
      backgroundColor: AppTheme.bgDeep,
      body: SafeArea(
        child: matchesAsync.when(
          data: (matches) {
            final canManagePosts =
                PermissionChecker.isAdmin(ref) || PermissionChecker.isCoach(ref);
            return CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                    child: _buildGreetingHeader(currentUser, canManagePosts)),
                if (activePolls.isNotEmpty)
                  SliverToBoxAdapter(
                    child: _buildActivePollBanner(context, activePolls.length),
                  ),
                if (upcomingNotices.isNotEmpty)
                  SliverToBoxAdapter(
                    child: _buildReservationNoticeBanner(
                      context,
                      upcomingNotices,
                    ),
                  ),
                if (recentPosts.isNotEmpty)
                  SliverToBoxAdapter(
                    child: _buildRecentNotice(context, recentPosts.first),
                  ),
                if (matches.isNotEmpty)
                  SliverToBoxAdapter(
                    child: _buildQuickStats(matches, allMembers.length),
                  ),
                if (matches.isEmpty)
                  const SliverFillRemaining(
                    child: Center(
                      child: Text(
                        '예정된 경기가 없습니다',
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 16,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  )
                else ...[
                  SliverToBoxAdapter(
                    child: _buildSectionLabel('다가오는 경기'),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) => Padding(
                          padding: const EdgeInsets.only(bottom: 20),
                          child: _MatchCard(
                            match: matches[index],
                            uid: currentUser?.uid,
                            isNext: index == 0,
                            pulseAnimation: _pulseController,
                          ),
                        ),
                        childCount: matches.length,
                      ),
                    ),
                  ),
                ],
              ],
            );
          },
          loading: () => const Center(
            child: CircularProgressIndicator(
              color: AppTheme.teamRed,
              strokeWidth: 2.5,
            ),
          ),
          error: (e, _) => Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, color: AppTheme.absentRed, size: 48),
                const SizedBox(height: 12),
                Text('데이터를 불러올 수 없습니다',
                    style: TextStyle(color: AppTheme.textSecondary, fontSize: 16)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _greetingText() {
    final hour = DateTime.now().hour;
    if (hour < 6) return '늦은 밤이에요';
    if (hour < 12) return '좋은 아침이에요';
    if (hour < 18) return '좋은 오후에요';
    return '좋은 저녁이에요';
  }

  Widget _buildGreetingHeader(dynamic currentUser, bool canManagePosts) {
    final userName = currentUser?.displayName ?? '선수';
    final now = DateTime.now();
    final dateStr = '${now.month}월 ${now.day}일 ${_weekdayFull(now.weekday)}';

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppTheme.teamRed,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: Text(
                    '영',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${_greetingText()}, $userName',
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      dateStr,
                      style: TextStyle(
                        color: AppTheme.textMuted,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              if (canManagePosts)
                IconButton(
                  icon: Icon(PhosphorIconsRegular.pencilSimple, color: AppTheme.textMuted, size: 24),
                  onPressed: () => context.push('/home/posts/create'),
                  tooltip: '공지 작성',
                ),
              IconButton(
                icon: Icon(PhosphorIconsRegular.megaphone, color: AppTheme.textMuted, size: 22),
                onPressed: () => context.push('/home/posts'),
                tooltip: '공지 목록',
              ),
              AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  return Opacity(
                    opacity: 0.5 + _pulseController.value * 0.5,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.attendGreen.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: AppTheme.attendGreen.withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: AppTheme.attendGreen,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Text(
                            'LIVE',
                            style: TextStyle(
                              color: AppTheme.attendGreen,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRecentNotice(BuildContext context, PostModel post) {
    final child = Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Row(
        children: [
          Icon(PhosphorIconsRegular.megaphone, color: AppTheme.textMuted, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              post.title,
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Icon(PhosphorIconsRegular.caretRight, color: AppTheme.textMuted, size: 18),
        ],
      ),
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
      child: GestureDetector(
        onTap: () => context.push('/home/posts/${post.postId}'),
        child: child,
      ),
    );
  }

  Widget _buildReservationNoticeBanner(
    BuildContext context,
    List<ReservationNoticeModel> notices,
  ) {
    final notice = notices.first;
    final typeLabel =
        notice.reservedForType == ReservationNoticeForType.class_
            ? '수업'
            : '매치';
    final dateStr =
        '${notice.targetDate.month}/${notice.targetDate.day} $typeLabel';
    final dDay = notice.openAt != null
        ? notice.openAt!.difference(DateTime.now()).inDays
        : 0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
      child: GestureDetector(
        onTap: () => context.push('/schedule/reservation-notices'),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: AppTheme.fixedBlue.withValues(alpha:0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.fixedBlue.withValues(alpha:0.3)),
          ),
          child: Row(
            children: [
              Icon(Icons.stadium, color: AppTheme.fixedBlue, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '다가오는 구장 예약: $dateStr',
                      style: const TextStyle(
                        color: AppTheme.fixedBlue,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (dDay >= 0)
                      Text(
                        'D-$dDay',
                        style: TextStyle(
                          color: AppTheme.textMuted,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: AppTheme.fixedBlue, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  /// 알람 창 스타일 (참고: 그린 배지 "You have 5 tasks today")
  Widget _buildActivePollBanner(BuildContext context, int count) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
      child: GestureDetector(
        onTap: () => context.push('/schedule/polls'),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: AppTheme.attendGreen.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.attendGreen.withValues(alpha: 0.4)),
          ),
          child: Row(
            children: [
              Icon(Icons.how_to_vote, color: AppTheme.attendGreen, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '회비·출석 투표 $count건 진행중',
                  style: const TextStyle(
                    color: AppTheme.attendGreen,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Icon(Icons.chevron_right, color: AppTheme.attendGreen, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickStats(List<Match> matches, int memberCount) {
    final nextMatch = matches.first;
    final daysUntil = nextMatch.date?.difference(DateTime(
                DateTime.now().year, DateTime.now().month, DateTime.now().day))
            .inDays;
    final dDayText = daysUntil == 0
        ? 'TODAY'
        : daysUntil == 1
            ? 'D-1'
            : 'D-${daysUntil ?? "?"}';
    final totalAttending =
        matches.fold<int>(0, (sum, m) => sum + (m.attendees?.length ?? 0));

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: Row(
        children: [
          _StatChip(
            icon: Icons.sports_soccer,
            label: '다음 경기',
            value: dDayText,
            color: AppTheme.teamRed,
          ),
          const SizedBox(width: 10),
          _StatChip(
            icon: Icons.event_available,
            label: '예정 경기',
            value: '${matches.length}',
            color: AppTheme.fixedBlue,
          ),
          const SizedBox(width: 10),
          _StatChip(
            icon: Icons.people_outline,
            label: '참석 합계',
            value: '$totalAttending',
            color: AppTheme.attendGreen,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 16,
            decoration: BoxDecoration(
              color: AppTheme.teamRed,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  String _weekdayFull(int wd) {
    const days = ['월요일', '화요일', '수요일', '목요일', '금요일', '토요일', '일요일'];
    return days[wd - 1];
  }
}

class _MatchCard extends ConsumerStatefulWidget {
  const _MatchCard({
    required this.match,
    required this.uid,
    required this.isNext,
    required this.pulseAnimation,
  });

  final Match match;
  final String? uid;
  final bool isNext;
  final Animation<double> pulseAnimation;

  @override
  ConsumerState<_MatchCard> createState() => _MatchCardState();
}

class _MatchCardState extends ConsumerState<_MatchCard> {
  /// Optimistic UI: null=없음, true=참석, false=불참
  bool? _optimisticVote;
  /// Optimistic UI: 공 가져가기 자원
  bool? _optimisticBallBring;

  Future<void> _handleBallBringToggle(Match match) async {
    if (widget.uid == null) return;
    final isBringing = match.ballBringers?.contains(widget.uid) ?? false;
    setState(() => _optimisticBallBring = !isBringing);
    try {
      await toggleBallBringer(ref, match, widget.uid!);
      if (mounted) setState(() => _optimisticBallBring = null);
    } catch (e) {
      if (mounted) {
        setState(() => _optimisticBallBring = null);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('반영 실패: $e')),
        );
      }
    }
  }

  Future<void> _handleVote(bool attend) async {
    if (widget.uid == null) return;

    // 불참: PRD에 따라 사유 입력 필수
    if (!attend) {
      _showReasonDialog();
      return;
    }

    // Optimistic UI: 바로 반영
    setState(() => _optimisticVote = true);
    try {
      await voteAttend(ref, widget.match, widget.uid!);
      if (mounted) setState(() => _optimisticVote = null);
    } catch (e) {
      if (mounted) {
        setState(() => _optimisticVote = null);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('참석 반영 실패: $e')),
        );
      }
    }
  }

  void _showReasonDialog() {
    final controller = TextEditingController();
    String? selectedReason;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return AlertDialog(
            backgroundColor: AppTheme.bgCard,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Text(
              '불참 사유를 알려주세요',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '당일 참석 변경은 사유 입력이 필요합니다.',
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: ['야근', '지각', '부상', '개인 사유'].map((reason) {
                    final isSelected = selectedReason == reason;
                    return GestureDetector(
                      onTap: () {
                        setDialogState(() {
                          selectedReason = reason;
                          controller.text = reason;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppTheme.teamRed.withValues(alpha:0.2)
                              : AppTheme.surface,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color:
                                isSelected ? AppTheme.teamRed : AppTheme.divider,
                            width: 1,
                          ),
                        ),
                        child: Text(
                          reason,
                          style: TextStyle(
                            color:
                                isSelected ? AppTheme.teamRed : AppTheme.textSecondary,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: controller,
                  style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: '직접 입력...',
                    hintStyle: TextStyle(color: AppTheme.textMuted, fontSize: 14),
                    filled: true,
                    fillColor: AppTheme.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: AppTheme.divider),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: AppTheme.divider),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AppTheme.teamRed),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                  ),
                  onChanged: (val) {
                    setDialogState(() => selectedReason = null);
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child:
                    const Text('취소', style: TextStyle(color: AppTheme.textMuted)),
              ),
              TextButton(
                onPressed: () async {
                  final reason = controller.text.trim();
                  if (reason.isEmpty) return;
                  Navigator.pop(ctx);
                  setState(() => _optimisticVote = false);
                  try {
                    await voteAbsentWithReason(
                      ref,
                      widget.match,
                      widget.uid!,
                      reason,
                    );
                    if (mounted) setState(() => _optimisticVote = null);
                  } catch (e) {
                    if (mounted) {
                      setState(() => _optimisticVote = null);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('불참 반영 실패: $e')),
                      );
                    }
                  }
                },
                child: const Text('확인',
                    style: TextStyle(
                        color: AppTheme.teamRed, fontWeight: FontWeight.w700)),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final match = widget.match;
    var attendees = List<String>.from(match.attendees ?? []);
    var absentees = List<String>.from(match.absentees ?? []);
    var ballBringers = List<String>.from(match.ballBringers ?? []);
    if (_optimisticVote != null && widget.uid != null) {
      attendees = attendees.where((u) => u != widget.uid).toList();
      absentees = absentees.where((u) => u != widget.uid).toList();
      if (_optimisticVote!) {
        attendees = [...attendees, widget.uid!];
      } else {
        absentees = [...absentees, widget.uid!];
      }
    }
    if (_optimisticBallBring != null && widget.uid != null) {
      ballBringers = ballBringers.where((u) => u != widget.uid).toList();
      if (_optimisticBallBring!) {
        ballBringers = [...ballBringers, widget.uid!];
      }
    }
    final isAttending = widget.uid != null && attendees.contains(widget.uid);
    final isAbsent = widget.uid != null && absentees.contains(widget.uid);
    final memberMap = ref.watch(memberMapProvider);
    final allMembers = ref.watch(teamMembersProvider).value ?? [];

    final daysUntil = match.date?.difference(DateTime(
                DateTime.now().year, DateTime.now().month, DateTime.now().day))
            .inDays;

    // 미투표 인원 계산
    final voted = {...attendees, ...absentees};
    final notVotedCount = allMembers
        .where((m) => !voted.contains(m.memberId))
        .length;

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: widget.isNext ? AppTheme.teamRed.withValues(alpha:0.4) : AppTheme.divider,
          width: widget.isNext ? 1.5 : 1,
        ),
      ),
      child: Column(
        children: [
          _buildTopBar(daysUntil, match.status),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            child: Column(
              children: [
                _buildOpponent(match.opponentName),
                const SizedBox(height: 20),
                _buildInfoGrid(match),
                const SizedBox(height: 20),
                _buildAttendanceBar(
                  attendees.length,
                  absentees.length,
                  match.effectiveMinPlayers,
                ),
                const SizedBox(height: 14),
                _buildAttendeeList(attendees, notVotedCount, memberMap),
                const SizedBox(height: 16),
                _buildBallBringerSection(
                  match.copyWith(ballBringers: ballBringers),
                  memberMap,
                ),
                const SizedBox(height: 20),
                _buildVoteButtons(isAttending, isAbsent),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar(int? daysUntil, MatchStatus? status) {
    final (statusLabel, statusColor) = switch (status) {
      MatchStatus.confirmed => ('CONFIRMED', AppTheme.attendGreen),
      MatchStatus.fixed => ('FIXED', AppTheme.fixedBlue),
      MatchStatus.pending => ('PENDING', AppTheme.gold),
      MatchStatus.inProgress => ('LIVE', AppTheme.teamRed),
      MatchStatus.finished => ('FINISHED', AppTheme.textMuted),
      MatchStatus.cancelled => ('CANCELLED', AppTheme.absentRed),
      null => ('TBD', AppTheme.textMuted),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: const BoxDecoration(
        color: AppTheme.bgCardLight,
        borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
      ),
      child: Row(
        children: [
          if (daysUntil != null && daysUntil >= 0) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: widget.isNext
                    ? AppTheme.teamRed.withValues(alpha:0.2)
                    : AppTheme.surface,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                daysUntil == 0
                    ? 'TODAY'
                    : daysUntil == 1
                        ? 'D-1'
                        : 'D-$daysUntil',
                style: TextStyle(
                  color: widget.isNext ? AppTheme.teamRed : AppTheme.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.0,
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Text(
            'MATCH DAY',
            style: TextStyle(
              color: AppTheme.textMuted,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 2.0,
            ),
          ),
          const Spacer(),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: statusColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                statusLabel,
                style: TextStyle(
                  color: statusColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOpponent(String? opponentName) {
    return Column(
      children: [
        Text(
          'VS',
          style: TextStyle(
            color: AppTheme.textMuted,
            fontSize: 13,
            fontWeight: FontWeight.w700,
            letterSpacing: 4.0,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          opponentName ?? '상대 미정',
          style: const TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 28,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.5,
            height: 1.2,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoGrid(Match match) {
    final dateStr = match.date != null
        ? '${match.date!.month}월 ${match.date!.day}일 (${_weekday(match.date!.weekday)})'
        : '미정';

    // 시간 미확정이면 "시간 미정" 표시
    final timeStr = (match.isTimeConfirmed ?? false)
        ? (match.startTime ?? '--:--')
        : '시간 미정';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface.withValues(alpha:0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.divider, width: 0.5),
      ),
      child: Row(
        children: [
          Expanded(
            child: _InfoCell(
              icon: Icons.calendar_today_outlined,
              label: '날짜',
              value: dateStr,
            ),
          ),
          Container(width: 1, height: 36, color: AppTheme.divider),
          Expanded(
            child: _InfoCell(
              icon: Icons.schedule_outlined,
              label: '시간',
              value: timeStr,
              isMuted: !(match.isTimeConfirmed ?? false),
            ),
          ),
          Container(width: 1, height: 36, color: AppTheme.divider),
          Expanded(
            child: _InfoCell(
              icon: Icons.location_on_outlined,
              label: '장소',
              value: match.location ?? '미정',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceBar(
      int attendCount, int absentCount, int minPlayers) {
    const totalMembers = 20;
    final progress = attendCount / totalMembers;
    final absentProgress = absentCount / totalMembers;
    final minProgress = minPlayers / totalMembers;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '출석 현황',
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
            RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: '$attendCount',
                    style: TextStyle(
                      color: attendCount >= minPlayers
                          ? AppTheme.attendGreen
                          : AppTheme.gold,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  TextSpan(
                    text: ' / $minPlayers명 필요',
                    style: TextStyle(
                      color: AppTheme.textMuted,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: SizedBox(
            height: 8,
            child: Stack(
              children: [
                Container(color: AppTheme.surface),
                // 불참 (오른쪽에서)
                Positioned.fill(
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: FractionallySizedBox(
                      widthFactor: absentProgress,
                      child: Container(
                        color: AppTheme.absentRed.withValues(alpha:0.4),
                      ),
                    ),
                  ),
                ),
                // 참석 (왼쪽에서)
                FractionallySizedBox(
                  widthFactor: progress,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppTheme.attendGreen,
                          AppTheme.attendGreen.withValues(alpha:0.7),
                        ],
                      ),
                    ),
                  ),
                ),
                // minPlayers 기준선
                Positioned(
                  left: minProgress *
                      (MediaQuery.of(context).size.width - 40 - 40),
                  top: 0,
                  bottom: 0,
                  child: Container(
                    width: 2,
                    color: AppTheme.gold.withValues(alpha:0.8),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            _Legend(color: AppTheme.attendGreen, label: '참석 $attendCount'),
            const SizedBox(width: 16),
            _Legend(
                color: AppTheme.absentRed.withValues(alpha:0.6),
                label: '불참 $absentCount'),
            const SizedBox(width: 16),
            _Legend(color: AppTheme.gold, label: '최소 $minPlayers명'),
          ],
        ),
      ],
    );
  }

  Widget _buildAttendeeList(
    List<String> attendeeUids,
    int notVotedCount,
    Map<String, Member> memberMap,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              '참석',
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              '${attendeeUids.length}명',
              style: const TextStyle(
                color: AppTheme.attendGreen,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
            const Spacer(),
            if (notVotedCount > 0)
              Text(
                '미정 $notVotedCount명',
                style: TextStyle(
                  color: AppTheme.textMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        if (attendeeUids.isEmpty)
          Text(
            '아직 참석자가 없습니다',
            style: TextStyle(
              color: AppTheme.textMuted,
              fontSize: 12,
              fontStyle: FontStyle.italic,
            ),
          )
        else
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: attendeeUids.map((uid) {
              final member = memberMap[uid];
              final name = member?.uniformName ?? member?.name ?? uid.substring(0, 4);
              final number = member?.number;
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppTheme.attendGreen.withValues(alpha:0.12),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppTheme.attendGreen.withValues(alpha:0.25),
                    width: 0.5,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (number != null) ...[
                      Text(
                        '#$number',
                        style: TextStyle(
                          color: AppTheme.attendGreen.withValues(alpha:0.7),
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 4),
                    ],
                    Text(
                      name,
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
      ],
    );
  }

  Widget _buildBallBringerSection(
    Match match,
    Map<String, Member> memberMap,
  ) {
    final ballBringers = match.ballBringers ?? [];
    final isBringing = widget.uid != null && ballBringers.contains(widget.uid);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.sports_soccer, size: 14, color: AppTheme.textMuted),
            const SizedBox(width: 6),
            Text(
              '공 가져오실 분?',
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            GestureDetector(
              onTap: widget.uid == null
                  ? null
                  : () => _handleBallBringToggle(match),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: isBringing
                      ? AppTheme.accentLime.withValues(alpha: 0.2)
                      : AppTheme.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isBringing
                        ? AppTheme.accentLime
                        : AppTheme.divider,
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isBringing ? Icons.check_circle : Icons.add_circle_outline,
                      size: 16,
                      color: isBringing
                          ? AppTheme.accentLime
                          : AppTheme.textSecondary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      isBringing ? '들고갈게요 ✓' : '저도 들고가요',
                      style: TextStyle(
                        color: isBringing
                            ? AppTheme.accentLime
                            : AppTheme.textSecondary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (ballBringers.isNotEmpty) ...[
              const SizedBox(width: 12),
              Expanded(
                child: Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: ballBringers.map((uid) {
                    final m = memberMap[uid];
                    final name = m?.uniformName ?? m?.name ?? uid.substring(0, 4);
                    return Text(
                      name,
                      style: TextStyle(
                        color: AppTheme.textMuted,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildVoteButtons(bool isAttending, bool isAbsent) {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () => _handleVote(true),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              height: 52,
              decoration: BoxDecoration(
                color: isAttending ? AppTheme.attendGreen : AppTheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isAttending ? AppTheme.attendGreen : AppTheme.divider,
                  width: 1.5,
                ),
              ),
              child: Center(
                child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isAttending
                                ? Icons.check_circle
                                : Icons.check_circle_outline,
                            size: 20,
                            color:
                                isAttending ? Colors.white : AppTheme.textSecondary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '참석',
                            style: TextStyle(
                              color: isAttending
                                  ? Colors.white
                                  : AppTheme.textSecondary,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: GestureDetector(
            onTap: () => _handleVote(false),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              height: 52,
              decoration: BoxDecoration(
                color: isAbsent ? AppTheme.absentRed : AppTheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isAbsent ? AppTheme.absentRed : AppTheme.divider,
                  width: 1.5,
                ),
              ),
              child: Center(
                child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isAbsent ? Icons.cancel : Icons.cancel_outlined,
                            size: 20,
                            color: isAbsent ? Colors.white : AppTheme.textSecondary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '불참',
                            style: TextStyle(
                              color:
                                  isAbsent ? Colors.white : AppTheme.textSecondary,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _weekday(int wd) {
    const days = ['월', '화', '수', '목', '금', '토', '일'];
    return days[wd - 1];
  }
}

// ── 서브 위젯 ──

class _InfoCell extends StatelessWidget {
  const _InfoCell({
    required this.icon,
    required this.label,
    required this.value,
    this.isMuted = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool isMuted;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 16, color: AppTheme.textMuted),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(
            color: AppTheme.textMuted,
            fontSize: 10,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: TextStyle(
            color: isMuted ? AppTheme.gold : AppTheme.textPrimary,
            fontSize: 13,
            fontWeight: FontWeight.w600,
            fontStyle: isMuted ? FontStyle.italic : FontStyle.normal,
          ),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            color: AppTheme.textMuted,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: AppTheme.bgCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.divider),
        ),
        child: Column(
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: AppTheme.textMuted,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
