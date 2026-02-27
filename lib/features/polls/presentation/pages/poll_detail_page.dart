import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_state_provider.dart';
import '../../../../core/permissions/permission_checker.dart';
import '../../../../core/widgets/error_retry_view.dart';
import '../../../events/presentation/providers/event_providers.dart';
import '../../../registrations/domain/entities/registration.dart';
import '../../../registrations/presentation/providers/registration_providers.dart';
import '../../../teams/presentation/providers/current_team_provider.dart';
import '../../../teams/presentation/providers/team_members_provider.dart';
import '../../domain/entities/poll.dart';
import '../../domain/services/poll_to_event_service.dart';
import '../providers/poll_providers.dart';

class _DS {
  _DS._();
  static const bgDeep = Color(0xFF0D1117);
  static const bgCard = Color(0xFF161B22);
  static const surface = Color(0xFF21262D);
  static const teamRed = Color(0xFFDC2626);
  static const textPrimary = Color(0xFFF0F6FC);
  static const textSecondary = Color(0xFF8B949E);
  static const textMuted = Color(0xFF484F58);
  static const attendGreen = Color(0xFF2EA043);
  static const divider = Color(0xFF30363D);
  static const gold = Color(0xFFFBBF24);
  static const fixedBlue = Color(0xFF58A6FF);
}

class PollDetailPage extends ConsumerWidget {
  const PollDetailPage({super.key, required this.pollId});
  final String pollId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pollAsync = ref.watch(pollDetailProvider(pollId));

    return Scaffold(
      backgroundColor: _DS.bgDeep,
      appBar: AppBar(
        backgroundColor: _DS.bgDeep,
        foregroundColor: _DS.textPrimary,
        title: const Text('투표 상세',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
        elevation: 0,
      ),
      body: pollAsync.when(
        data: (poll) {
          if (poll == null) {
            return const Center(
                child: Text('투표를 찾을 수 없습니다',
                    style: TextStyle(color: _DS.textSecondary)));
          }
          return _PollDetailBody(poll: poll);
        },
        loading: () => const Center(
            child: CircularProgressIndicator(
                color: _DS.teamRed, strokeWidth: 2.5)),
        error: (e, _) => ErrorRetryView(
            message: '투표를 불러올 수 없습니다',
            detail: e.toString(),
            onRetry: () => ref.invalidate(pollDetailProvider(pollId))),
      ),
    );
  }
}

class _PollDetailBody extends ConsumerStatefulWidget {
  const _PollDetailBody({required this.poll});
  final Poll poll;

  @override
  ConsumerState<_PollDetailBody> createState() => _PollDetailBodyState();
}

class _PollDetailBodyState extends ConsumerState<_PollDetailBody> {
  bool _isCreating = false;
  /// Optimistic UI: 탭 즉시 반영용
  final Set<String> _optimisticVotes = {};
  final Set<String> _optimisticUnvotes = {};
  /// 옵션별 로딩: 저장 중인 옵션 ID
  String? _votingOptionId;

  Future<void> _createEventsFromPoll() async {
    final poll = widget.poll;
    if (poll.category != PollCategory.attendance ||
        poll.linkedEventId != null ||
        _isCreating) {
      return;
    }

    final uid = ref.read(currentUserProvider)?.uid;
    final teamId = ref.read(currentTeamIdProvider);
    if (uid == null || teamId == null) return;
    if (!PermissionChecker.isAdmin(ref) && !PermissionChecker.isCoach(ref)) {
      return;
    }

    setState(() => _isCreating = true);
    try {
      final memberMap = ref.read(memberMapProvider);
      final events = PollToEventService.createEventsFromAttendancePoll(
        poll: poll,
        memberMap: memberMap,
        createdBy: uid,
      );
      if (events.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('생성할 수업 일정이 없습니다')),
          );
        }
        return;
      }
      final eventDs = ref.read(eventDataSourceProvider);
      final pollDs = ref.read(pollDataSourceProvider);
      final firstId = await eventDs.createClassesBatch(teamId, events);
      if (firstId != null) {
        await pollDs.setLinkedEventId(teamId, poll.pollId, firstId);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${events.length}개 수업 일정이 생성되었습니다')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('오류: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isCreating = false);
    }
  }

  Future<void> _toggleVote(String optionId, bool isVoted) async {
    final uid = ref.read(currentUserProvider)?.uid;
    final teamId = ref.read(currentTeamIdProvider);
    if (uid == null || teamId == null) return;

    // Optimistic UI: 바로 반영
    setState(() {
      if (isVoted) {
        _optimisticUnvotes.add(optionId);
        _optimisticVotes.remove(optionId);
      } else {
        _optimisticVotes.add(optionId);
        _optimisticUnvotes.remove(optionId);
        // 단일 선택: 기존 선택 제거
        if (widget.poll.maxSelections == 1) {
          for (final o in widget.poll.options ?? <PollOption>[]) {
            if (o.id != optionId && (o.votes?.contains(uid) ?? false)) {
              _optimisticUnvotes.add(o.id);
              _optimisticVotes.remove(o.id);
            }
          }
        }
      }
    });

    setState(() => _votingOptionId = optionId);
    try {
      final ds = ref.read(pollDataSourceProvider);
      if (isVoted) {
        await ds.unvote(teamId, widget.poll.pollId, optionId, uid);
      } else {
        if (widget.poll.maxSelections == 1) {
          for (final o in widget.poll.options ?? <PollOption>[]) {
            if (o.votes?.contains(uid) ?? false) {
              await ds.unvote(teamId, widget.poll.pollId, o.id, uid);
            }
          }
        }
        await ds.vote(teamId, widget.poll.pollId, optionId, uid);

        if (widget.poll.category == PollCategory.membership &&
            widget.poll.targetMonth != null) {
          final status = MembershipStatus.fromString(optionId);
          if (status != null) {
            final memberMap = ref.read(memberMapProvider);
            final member = memberMap[uid];
            final userName = member?.uniformName ?? member?.name;
            await ref.read(registrationDataSourceProvider).upsertMembershipRegistration(
                  teamId: teamId,
                  seasonId: widget.poll.targetMonth!,
                  userId: uid,
                  membershipStatus: status,
                  userName: userName,
                  uniformNo: member?.number,
                  photoUrl: member?.photoUrl,
                );
          }
        }
      }
      if (mounted) {
        setState(() {
        _optimisticVotes.clear();
        _optimisticUnvotes.clear();
      });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _optimisticVotes.clear();
          _optimisticUnvotes.clear();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('투표 반영 실패: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _votingOptionId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final poll = widget.poll;
    final uid = ref.watch(currentUserProvider)?.uid;
    final memberMap = ref.watch(memberMapProvider);
    final isActive = poll.isActive ?? false;
    final options = poll.options ?? [];
    final totalVotes =
        options.fold<int>(0, (sum, o) => sum + (o.voteCount ?? 0));
    final isMultiSelect = (poll.maxSelections ?? 0) != 1;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // 제목 카드
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: _DS.bgCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _DS.divider),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: isActive
                          ? _DS.attendGreen.withValues(alpha:0.15)
                          : _DS.surface,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(isActive ? '진행중' : '종료',
                        style: TextStyle(
                            color: isActive
                                ? _DS.attendGreen
                                : _DS.textMuted,
                            fontSize: 11,
                            fontWeight: FontWeight.w700)),
                  ),
                  const SizedBox(width: 8),
                  Text(isMultiSelect ? '복수선택' : '단일선택',
                      style: TextStyle(
                          color: _DS.textMuted,
                          fontSize: 11,
                          fontWeight: FontWeight.w600)),
                  const Spacer(),
                  Text('$totalVotes명 참여',
                      style: TextStyle(
                          color: _DS.textSecondary,
                          fontSize: 13,
                          fontWeight: FontWeight.w600)),
                ],
              ),
              const SizedBox(height: 14),
              Text(poll.title,
                  style: const TextStyle(
                      color: _DS.textPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.w800)),
              if (poll.description != null) ...[
                const SizedBox(height: 6),
                Text(poll.description!,
                    style: const TextStyle(
                        color: _DS.textSecondary, fontSize: 14)),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),
        // 옵션 목록
        ...options.map((option) {
          final baseVoted = option.votes?.contains(uid) ?? false;
          final isVoted = _optimisticUnvotes.contains(option.id)
              ? false
              : (_optimisticVotes.contains(option.id) || baseVoted);
          final countDelta = (_optimisticVotes.contains(option.id) ? 1 : 0) -
              (_optimisticUnvotes.contains(option.id) ? 1 : 0);
          final count = (option.voteCount ?? 0) + countDelta;
          final totalWithOptimistic =
              totalVotes + _optimisticVotes.length - _optimisticUnvotes.length;
          final ratio = totalWithOptimistic > 0 ? count / totalWithOptimistic : 0.0;
          var voters = List<String>.from(option.votes ?? []);
          if (uid != null &&
              _optimisticVotes.contains(option.id) &&
              !voters.contains(uid)) {
            voters = [...voters, uid];
          }
          if (_optimisticUnvotes.contains(option.id)) {
            voters = voters.where((v) => v != uid).toList();
          }

          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: GestureDetector(
              onTap: isActive && _votingOptionId != option.id
                  ? () {
                      HapticFeedback.lightImpact();
                      _toggleVote(option.id, isVoted);
                    }
                  : null,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isVoted
                      ? _DS.gold.withValues(alpha:0.08)
                      : _DS.bgCard,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: isVoted
                          ? _DS.gold.withValues(alpha:0.4)
                          : _DS.divider,
                      width: isVoted ? 1.5 : 1),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          isVoted
                              ? Icons.check_circle
                              : Icons.radio_button_unchecked,
                          size: 20,
                          color:
                              isVoted ? _DS.gold : _DS.textMuted,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(option.text ?? '옵션',
                              style: TextStyle(
                                  color: _DS.textPrimary,
                                  fontSize: 15,
                                  fontWeight: isVoted
                                      ? FontWeight.w700
                                      : FontWeight.w500)),
                        ),
                        if (_votingOptionId == option.id)
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: _DS.gold,
                              ),
                            ),
                          )
                        else
                          Text('$count명',
                              style: TextStyle(
                                  color: isVoted
                                      ? _DS.gold
                                      : _DS.textMuted,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700)),
                      ],
                    ),
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: SizedBox(
                        height: 6,
                        child: LinearProgressIndicator(
                          value: ratio,
                          backgroundColor: _DS.surface,
                          color: isVoted ? _DS.gold : _DS.fixedBlue,
                        ),
                      ),
                    ),
                    // 투표자 이름 표시
                    if (voters.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 4,
                        runSpacing: 4,
                        children: voters.map((voterId) {
                          final member = memberMap[voterId];
                          final name = member?.uniformName ??
                              member?.name ??
                              voterId.substring(
                                  0, voterId.length.clamp(0, 4));
                          return Text(name,
                              style: TextStyle(
                                  color: _DS.textMuted,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500));
                        }).toList(),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        }),
        // 출석 투표 → 수업 일정 생성 버튼 (운영진만)
        if (poll.category == PollCategory.attendance &&
            poll.isActive == false &&
            (PermissionChecker.isAdmin(ref) || PermissionChecker.isCoach(ref))) ...[
          const SizedBox(height: 20),
          if (poll.linkedEventId != null)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _DS.attendGreen.withValues(alpha:0.15),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _DS.attendGreen.withValues(alpha:0.4)),
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle, color: _DS.attendGreen, size: 24),
                  const SizedBox(width: 12),
                  Text('수업 일정이 이미 생성되었습니다',
                      style: TextStyle(
                          color: _DS.attendGreen,
                          fontSize: 14,
                          fontWeight: FontWeight.w600)),
                ],
              ),
            )
          else
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isCreating ? null : _createEventsFromPoll,
                icon: _isCreating
                    ? SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: _DS.textPrimary,
                        ),
                      )
                    : const Icon(Icons.event_note, size: 20),
                label: Text(_isCreating ? '생성 중...' : '수업 일정 생성'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _DS.teamRed,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
        ],
      ],
    );
  }
}
