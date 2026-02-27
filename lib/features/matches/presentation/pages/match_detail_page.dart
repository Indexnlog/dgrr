import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/errors.dart';

import '../../../auth/presentation/providers/auth_state_provider.dart';
import '../../../opponents/domain/entities/opponent.dart';
import '../../../opponents/presentation/providers/opponent_providers.dart';
import '../../../teams/presentation/providers/current_team_provider.dart';
import '../../../teams/domain/entities/member.dart';
import '../../../teams/presentation/providers/team_members_provider.dart';
import '../../../teams/presentation/providers/user_role_provider.dart';
import '../../domain/entities/match.dart';
import '../../domain/entities/record.dart';
import '../../domain/entities/round.dart';
import '../providers/match_detail_providers.dart';
import '../providers/match_providers.dart';
import '../../../match_media/presentation/widgets/match_media_section.dart';
import 'lineup_edit_sheet.dart';
import 'record_modals.dart';

class _C {
  _C._();
  static const bg = Color(0xFF0D1117);
  static const card = Color(0xFF161B22);
  static const cardLight = Color(0xFF1C2333);
  static const surface = Color(0xFF21262D);
  static const red = Color(0xFFDC2626);
  static const green = Color(0xFF2EA043);
  static const blue = Color(0xFF58A6FF);
  static const gold = Color(0xFFFBBF24);
  static const text = Color(0xFFF0F6FC);
  static const sub = Color(0xFF8B949E);
  static const muted = Color(0xFF484F58);
  static const divider = Color(0xFF30363D);
}

class MatchDetailPage extends ConsumerStatefulWidget {
  const MatchDetailPage({super.key, required this.matchId});

  final String matchId;

  @override
  ConsumerState<MatchDetailPage> createState() => _MatchDetailPageState();
}

class _MatchDetailPageState extends ConsumerState<MatchDetailPage> {
  String? _expandedRoundId;

  @override
  Widget build(BuildContext context) {
    final matchAsync = ref.watch(matchDetailProvider(widget.matchId));
    final roundsAsync = ref.watch(matchRoundsProvider(widget.matchId));

    return Scaffold(
      backgroundColor: _C.bg,
      appBar: AppBar(
        backgroundColor: _C.card,
        foregroundColor: _C.text,
        title: const Text('경기 상세'),
        elevation: 0,
      ),
      body: matchAsync.when(
        data: (match) {
          if (match == null) {
            return const Center(
              child: Text('경기를 찾을 수 없습니다', style: TextStyle(color: _C.sub)),
            );
          }
          return _buildBody(match, roundsAsync);
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: _C.red),
        ),
        error: (e, _) => Center(
          child: Text('오류: $e', style: const TextStyle(color: _C.sub)),
        ),
      ),
      floatingActionButton: matchAsync.value != null
          ? _buildFab(matchAsync.value!)
          : null,
    );
  }

  int? _daysUntil(Match match) {
    if (match.date == null) return null;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final matchDay = DateTime(match.date!.year, match.date!.month, match.date!.day);
    return matchDay.difference(today).inDays;
  }

  Widget _buildBody(Match match, AsyncValue<List<Round>> roundsAsync) {
    final daysUntil = _daysUntil(match);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (daysUntil != null && daysUntil >= 0) ...[
          _DDayBanner(daysUntil: daysUntil),
          const SizedBox(height: 16),
        ],
        _MatchInfoCard(match: match, matchId: widget.matchId),
        const SizedBox(height: 12),
        _BallBringerChip(match: match),
        const SizedBox(height: 16),
        _GameControlBar(
          match: match,
          matchId: widget.matchId,
        ),
        const SizedBox(height: 20),
        _LineupSection(match: match, matchId: widget.matchId),
        const SizedBox(height: 20),
        MatchMediaSection(
          matchId: widget.matchId,
          opponentName: match.opponentName,
        ),
        const SizedBox(height: 20),
        _SectionHeader(
          title: '라운드',
          trailing: match.gameStatus == GameStatus.playing
              ? _AddRoundButton(matchId: widget.matchId)
              : null,
        ),
        const SizedBox(height: 8),
        roundsAsync.when(
          data: (rounds) {
            if (rounds.isEmpty) {
              return _EmptyState(
                icon: Icons.sports,
                message: '경기를 시작하고 라운드를 추가하세요',
              );
            }
            return Column(
              children: rounds.map((round) {
                final isExpanded = _expandedRoundId == round.roundId;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _RoundCard(
                    round: round,
                    matchId: widget.matchId,
                    isExpanded: isExpanded,
                    onToggle: () {
                      setState(() {
                        _expandedRoundId = isExpanded ? null : round.roundId;
                      });
                    },
                  ),
                );
              }).toList(),
            );
          },
          loading: () => const Center(
            child: CircularProgressIndicator(color: _C.red, strokeWidth: 2),
          ),
          error: (e, _) => Text('$e', style: const TextStyle(color: _C.sub)),
        ),
      ],
    );
  }

  Widget? _buildFab(Match match) {
    if (match.gameStatus != GameStatus.playing) return null;
    final roundsAsync = ref.watch(matchRoundsProvider(widget.matchId));
    final playingRound = roundsAsync.value
        ?.where((r) => r.status == RoundStatus.playing)
        .firstOrNull;
    if (playingRound == null) return null;

    return FloatingActionButton.extended(
      backgroundColor: _C.red,
      foregroundColor: Colors.white,
      icon: const Icon(Icons.add, size: 20),
      label: const Text('기록 추가', style: TextStyle(fontWeight: FontWeight.w700)),
      onPressed: () => _showRecordTypeSheet(playingRound, match),
    );
  }

  void _showRecordTypeSheet(Round round, Match match) {
    final teamId = ref.read(currentTeamIdProvider);
    if (teamId == null) return;
    final allMembers = ref.read(teamMembersProvider).value ?? [];
    final memberMap = ref.read(memberMapProvider);
    final uid = ref.read(currentUserProvider)?.uid;
    final elapsed = round.startTime != null
        ? DateTime.now().difference(round.startTime!).inSeconds
        : 0;
    final dataSource = ref.read(roundRecordDataSourceProvider);

    final lineupUids = match.lineup ?? match.participants ?? match.attendees ?? [];
    final lineupMembers = lineupUids.map((id) => memberMap[id]).whereType<Member>().toList();
    final quickGoalMembers = lineupMembers.isEmpty ? allMembers : lineupMembers;

    final fieldResult = ref.read(currentFieldPlayersProvider((matchId: widget.matchId, roundId: round.roundId)));
    final fieldMembers = (fieldResult?.fieldUids ?? [])
        .map((id) => memberMap[id])
        .whereType<Member>()
        .toList();
    final benchMembers = (fieldResult?.benchUids ?? [])
        .map((id) => memberMap[id])
        .whereType<Member>()
        .toList();

    showModalBottomSheet(
      context: context,
      backgroundColor: _C.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: _C.muted,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.sports_soccer, color: _C.green),
              title: const Text('골 (빠른 기록)', style: TextStyle(color: _C.text, fontWeight: FontWeight.w600)),
              subtitle: const Text('득점자 1탭', style: TextStyle(color: _C.sub, fontSize: 12)),
              onTap: () {
                Navigator.pop(ctx);
                showQuickGoalSheet(
                  context: context,
                  teamId: teamId,
                  matchId: widget.matchId,
                  roundId: round.roundId,
                  members: quickGoalMembers,
                  elapsedSeconds: elapsed,
                  dataSource: dataSource,
                  createdBy: uid,
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.swap_horiz, color: _C.blue),
              title: const Text('교체 (빠른 기록)', style: TextStyle(color: _C.text, fontWeight: FontWeight.w600)),
              subtitle: const Text('OUT → IN 선택', style: TextStyle(color: _C.sub, fontSize: 12)),
              onTap: () {
                Navigator.pop(ctx);
                showQuickSubstitutionSheet(
                  context: context,
                  teamId: teamId,
                  matchId: widget.matchId,
                  roundId: round.roundId,
                  fieldMembers: fieldMembers,
                  benchMembers: benchMembers,
                  elapsedSeconds: elapsed,
                  dataSource: dataSource,
                  createdBy: uid,
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.sports, color: _C.muted),
              title: const Text('상대팀 골', style: TextStyle(color: _C.text, fontWeight: FontWeight.w600)),
              subtitle: const Text('+1 즉시 기록', style: TextStyle(color: _C.sub, fontSize: 12)),
              onTap: () async {
                Navigator.pop(ctx);
                try {
                  await dataSource.addGoalRecord(
                    teamId: teamId,
                    matchId: widget.matchId,
                    roundId: round.roundId,
                    teamType: TeamType.opponent,
                    timeOffset: elapsed,
                    createdBy: uid,
                  );
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('상대팀 골 기록'), backgroundColor: _C.green),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ErrorHandler.showError(context, e, fallback: '저장에 실패했습니다');
                  }
                }
              },
            ),
            const Divider(color: _C.divider, height: 1, indent: 16, endIndent: 16),
            ListTile(
              leading: const Icon(Icons.edit, color: _C.muted, size: 20),
              title: const Text('득점 기록 (상세)', style: TextStyle(color: _C.sub, fontWeight: FontWeight.w600, fontSize: 13)),
              subtitle: const Text('골 / 도움 / 자책골', style: TextStyle(color: _C.muted, fontSize: 11)),
              onTap: () {
                Navigator.pop(ctx);
                showGoalRecordModal(
                  context: context,
                  teamId: teamId,
                  matchId: widget.matchId,
                  roundId: round.roundId,
                  members: allMembers,
                  elapsedSeconds: elapsed,
                  createdBy: uid,
                  dataSource: dataSource,
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.edit, color: _C.muted, size: 20),
              title: const Text('교체 기록 (상세)', style: TextStyle(color: _C.sub, fontWeight: FontWeight.w600, fontSize: 13)),
              subtitle: const Text('IN / OUT 선수 선택', style: TextStyle(color: _C.muted, fontSize: 11)),
              onTap: () {
                Navigator.pop(ctx);
                showSubstitutionRecordModal(
                  context: context,
                  teamId: teamId,
                  matchId: widget.matchId,
                  roundId: round.roundId,
                  members: allMembers,
                  elapsedSeconds: elapsed,
                  createdBy: uid,
                  dataSource: dataSource,
                );
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

// ── D-day 배너 ──

class _DDayBanner extends StatelessWidget {
  const _DDayBanner({required this.daysUntil});
  final int daysUntil;

  @override
  Widget build(BuildContext context) {
    final label = daysUntil == 0 ? 'D-day' : 'D-$daysUntil';
    final isToday = daysUntil == 0;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: isToday ? _C.red.withValues(alpha:0.15) : _C.muted.withValues(alpha:0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isToday ? _C.red.withValues(alpha:0.5) : _C.muted.withValues(alpha:0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isToday ? Icons.today : Icons.event,
            size: 20,
            color: isToday ? _C.red : _C.muted,
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: isToday ? _C.red : _C.muted,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          if (isToday) ...[
            const SizedBox(width: 8),
            Text(
              '오늘 경기입니다!',
              style: TextStyle(color: _C.red.withValues(alpha:0.9), fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ],
        ],
      ),
    );
  }
}

// ── 라인업 섹션 ──

class _LineupSection extends ConsumerWidget {
  const _LineupSection({required this.match, required this.matchId});
  final Match match;
  final String matchId;

  bool _isLineupVisible(Match m) {
    if (m.lineup == null || m.lineup!.isEmpty) return false;
    if (m.lineupAnnouncedAt == null) return true;
    return DateTime.now().isAfter(m.lineupAnnouncedAt!);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final canEdit = ref.watch(hasPermissionProvider(Permission.coach));
    final memberMap = ref.watch(memberMapProvider);
    final isVisible = _isLineupVisible(match);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _C.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _C.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                '라인업',
                style: TextStyle(color: _C.text, fontSize: 16, fontWeight: FontWeight.w700),
              ),
              const Spacer(),
              if (canEdit)
                GestureDetector(
                  onTap: () => showLineupEditSheet(context, match: match, matchId: matchId),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _C.green.withValues(alpha:0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: _C.green.withValues(alpha:0.4)),
                    ),
                    child: const Text(
                      '라인업 설정',
                      style: TextStyle(color: _C.green, fontSize: 12, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (!isVisible)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  match.lineup != null && match.lineup!.isNotEmpty
                      ? '경기 당일 공개'
                      : '라인업을 설정해 주세요',
                  style: const TextStyle(color: _C.muted, fontSize: 14),
                ),
              ),
            )
          else ...[
            _LineupRow(
              label: '선발',
              uids: match.lineup!.take(match.effectiveLineupSize).toList(),
              memberMap: memberMap,
              captainId: match.captainId,
            ),
            const SizedBox(height: 12),
            _LineupRow(
              label: '벤치',
              uids: match.lineup!.skip(match.effectiveLineupSize).toList(),
              memberMap: memberMap,
              captainId: match.captainId,
            ),
          ],
        ],
      ),
    );
  }
}

class _LineupRow extends StatelessWidget {
  const _LineupRow({
    required this.label,
    required this.uids,
    required this.memberMap,
    required this.captainId,
  });
  final String label;
  final List<String> uids;
  final Map<String, Member> memberMap;
  final String? captainId;

  @override
  Widget build(BuildContext context) {
    if (uids.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: _C.sub, fontSize: 12, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: uids.map((uid) {
            final m = memberMap[uid];
            final isCaptain = captainId == uid;
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: _C.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _C.divider),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (m?.number != null)
                    Text(
                      '${m!.number}번 ',
                      style: const TextStyle(color: _C.sub, fontSize: 12),
                    ),
                  Text(
                    m?.name ?? uid,
                    style: TextStyle(
                      color: _C.text,
                      fontSize: 13,
                      fontWeight: isCaptain ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                  if (isCaptain)
                    const Text(' (주장)', style: TextStyle(color: _C.green, fontSize: 11)),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

// ── 경기 정보 카드 ──

class _MatchInfoCard extends ConsumerWidget {
  const _MatchInfoCard({required this.match, required this.matchId});
  final Match match;
  final String matchId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final canEdit = ref.watch(hasPermissionProvider(Permission.coach));
    final dateStr = match.date != null
        ? '${match.date!.year}.${match.date!.month.toString().padLeft(2, '0')}.${match.date!.day.toString().padLeft(2, '0')}'
        : '미정';
    final timeStr = match.startTime ?? '--:--';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _C.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _C.divider),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('VS', style: TextStyle(color: _C.muted, fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 4)),
              if (canEdit) ...[
                const Spacer(),
                GestureDetector(
                  onTap: () => _showOpponentEditDialog(context, ref, match, matchId),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _C.muted.withValues(alpha:0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text('상대팀 수정', style: TextStyle(color: _C.sub, fontSize: 11, fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 4),
          Text(
            match.opponentName ?? '상대 미정',
            style: const TextStyle(color: _C.text, fontSize: 24, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _InfoChip(icon: Icons.calendar_today, label: dateStr),
              const SizedBox(width: 12),
              _InfoChip(icon: Icons.schedule, label: timeStr),
              const SizedBox(width: 12),
              _InfoChip(icon: Icons.location_on, label: match.location ?? '미정'),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _showOpponentEditDialog(BuildContext context, WidgetRef ref, Match match, String matchId) async {
    final teamId = ref.read(currentTeamIdProvider);
    if (teamId == null) return;

    final nameController = TextEditingController(text: match.opponent?.name ?? '');
    final contactController = TextEditingController(text: match.opponent?.contact ?? '');
    var status = match.opponent?.status ?? 'seeking';

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          backgroundColor: _C.card,
          title: const Text('상대팀 수정', style: TextStyle(color: _C.text)),
          content: SizedBox(
            width: 320,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('상대팀명', style: TextStyle(color: _C.sub, fontSize: 12)),
                const SizedBox(height: 4),
                TextField(
                  controller: nameController,
                  style: const TextStyle(color: _C.text),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: _C.surface,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
                const SizedBox(height: 16),
                const Text('연락처', style: TextStyle(color: _C.sub, fontSize: 12)),
                const SizedBox(height: 4),
                TextField(
                  controller: contactController,
                  style: const TextStyle(color: _C.text),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: _C.surface,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
                const SizedBox(height: 16),
                const Text('상태', style: TextStyle(color: _C.sub, fontSize: 12)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _StatusChip(label: '모집 중', value: 'seeking', selected: status == 'seeking', onTap: () => setState(() => status = 'seeking')),
                    const SizedBox(width: 8),
                    _StatusChip(label: '확정', value: 'confirmed', selected: status == 'confirmed', onTap: () => setState(() => status = 'confirmed')),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('취소', style: TextStyle(color: _C.muted))),
            TextButton(
              onPressed: () {
                if (nameController.text.trim().isEmpty) return;
                Navigator.pop(ctx, true);
              },
              child: const Text('저장', style: TextStyle(color: _C.green)),
            ),
          ],
        ),
      ),
    );

    if (result == true && nameController.text.trim().isNotEmpty) {
      try {
        await ref.read(matchDataSourceProvider).updateOpponent(
          teamId,
          matchId,
          name: nameController.text.trim(),
          contact: contactController.text.trim().isEmpty ? null : contactController.text.trim(),
          status: status,
        );
        final opponentId = match.opponent?.teamId;
        if (opponentId != null) {
          await ref.read(opponentDataSourceProvider).updateOpponent(
            teamId,
            opponentId,
            name: nameController.text.trim(),
            contact: contactController.text.trim().isEmpty ? null : contactController.text.trim(),
            status: status,
          );
        }
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('상대팀 정보가 수정되었습니다'), backgroundColor: _C.green),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ErrorHandler.showError(context, e, fallback: '수정에 실패했습니다');
        }
      }
    }
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label, required this.value, required this.selected, required this.onTap});
  final String label;
  final String value;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? _C.green.withValues(alpha:0.15) : _C.muted.withValues(alpha:0.2),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? _C.green : _C.divider),
        ),
        child: Text(label, style: TextStyle(color: selected ? _C.green : _C.sub, fontWeight: FontWeight.w600)),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: _C.surface,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: _C.sub),
          const SizedBox(width: 5),
          Text(label, style: const TextStyle(color: _C.sub, fontSize: 11, fontWeight: FontWeight.w500),
               maxLines: 1, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}

// ── 공 가져가기 ("저도 들고가요") ──

class _BallBringerChip extends ConsumerWidget {
  const _BallBringerChip({required this.match});
  final Match match;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uid = ref.watch(currentUserProvider)?.uid;
    final memberMap = ref.watch(memberMapProvider);
    final ballBringers = match.ballBringers ?? [];
    final isBringing = uid != null && ballBringers.contains(uid);

    return Row(
      children: [
        Icon(Icons.sports_soccer, size: 16, color: _C.muted),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: uid == null ? null : () => toggleBallBringer(ref, match, uid),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: isBringing ? _C.green.withValues(alpha: 0.15) : _C.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isBringing ? _C.green : _C.divider,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isBringing ? Icons.check_circle : Icons.add_circle_outline,
                  size: 14,
                  color: isBringing ? _C.green : _C.sub,
                ),
                const SizedBox(width: 6),
                Text(
                  isBringing ? '들고갈게요 ✓' : '저도 들고가요',
                  style: TextStyle(
                    color: isBringing ? _C.green : _C.sub,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (ballBringers.isNotEmpty) ...[
          const SizedBox(width: 12),
          ...ballBringers.map((u) {
            final m = memberMap[u];
            final name = m?.uniformName ?? m?.name ?? u.substring(0, 4);
            return Padding(
              padding: const EdgeInsets.only(right: 6),
              child: Text(
                name,
                style: const TextStyle(color: _C.muted, fontSize: 11),
              ),
            );
          }),
        ],
      ],
    );
  }
}

// ── 경기 시작/종료 컨트롤 바 ──

class _GameControlBar extends ConsumerWidget {
  const _GameControlBar({required this.match, required this.matchId});
  final Match match;
  final String matchId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gameStatus = match.gameStatus ?? GameStatus.notStarted;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: _C.cardLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _C.divider),
      ),
      child: Row(
        children: [
          Container(
            width: 8, height: 8,
            decoration: BoxDecoration(
              color: switch (gameStatus) {
                GameStatus.notStarted => _C.muted,
                GameStatus.playing => _C.green,
                GameStatus.finished => _C.sub,
              },
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Text(
            switch (gameStatus) {
              GameStatus.notStarted => '경기 시작 전',
              GameStatus.playing => '경기 진행 중',
              GameStatus.finished => '경기 종료',
            },
            style: const TextStyle(color: _C.text, fontSize: 14, fontWeight: FontWeight.w600),
          ),
          const Spacer(),
          if (gameStatus == GameStatus.notStarted)
            _ActionButton(
              label: '경기 시작',
              color: _C.green,
              onTap: () async {
                final teamId = ref.read(currentTeamIdProvider);
                if (teamId == null) return;
                await ref.read(roundRecordDataSourceProvider).startMatch(teamId, matchId);
                await ref.read(matchDataSourceProvider).syncParticipantsFromAttendees(teamId, matchId);
              },
            ),
          if (gameStatus == GameStatus.playing)
            _ActionButton(
              label: '경기 종료',
              color: _C.red,
              onTap: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    backgroundColor: _C.card,
                    title: const Text('경기 종료', style: TextStyle(color: _C.text)),
                    content: const Text('경기를 종료하시겠습니까?', style: TextStyle(color: _C.sub)),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('취소', style: TextStyle(color: _C.muted))),
                      TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('종료', style: TextStyle(color: _C.red))),
                    ],
                  ),
                );
                if (confirm == true) {
                  final teamId = ref.read(currentTeamIdProvider);
                  if (teamId == null) return;
                  await ref.read(roundRecordDataSourceProvider).endMatch(teamId, matchId);

                  final opponentId = match.opponent?.teamId;
                  if (opponentId != null) {
                    final rounds = ref.read(matchRoundsProvider(matchId)).value ?? [];
                    var ourTotal = 0;
                    var oppTotal = 0;
                    for (final r in rounds) {
                      ourTotal += r.ourScore ?? 0;
                      oppTotal += r.oppScore ?? 0;
                    }
                    final result = ourTotal > oppTotal ? 'W' : ourTotal < oppTotal ? 'L' : 'D';
                    final oppDs = ref.read(opponentDataSourceProvider);
                    final current = await oppDs.getOpponent(teamId, opponentId);
                    final rec = current?.records ?? const OpponentRecords();
                    final newRec = OpponentRecords(
                      wins: rec.wins + (result == 'W' ? 1 : 0),
                      draws: rec.draws + (result == 'D' ? 1 : 0),
                      losses: rec.losses + (result == 'L' ? 1 : 0),
                    );
                    final recent = [...?current?.recentResults];
                    recent.insert(0, result);
                    if (recent.length > 10) recent.removeLast();
                    await oppDs.updateRecords(teamId, opponentId, recentResults: recent, records: newRec);
                  }
                }
              },
            ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({required this.label, required this.color, required this.onTap});
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha:0.15),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha:0.4)),
        ),
        child: Text(label, style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w700)),
      ),
    );
  }
}

// ── 라운드 추가 버튼 ──

class _AddRoundButton extends ConsumerWidget {
  const _AddRoundButton({required this.matchId});
  final String matchId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () async {
        final teamId = ref.read(currentTeamIdProvider);
        if (teamId == null) return;
        final rounds = ref.read(matchRoundsProvider(matchId)).value ?? [];
        final nextIndex = rounds.length + 1;
        await ref.read(roundRecordDataSourceProvider).createRound(teamId, matchId, nextIndex);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: _C.blue.withValues(alpha:0.12),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: _C.blue.withValues(alpha:0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.add, size: 14, color: _C.blue),
            const SizedBox(width: 4),
            Text('라운드 추가', style: TextStyle(color: _C.blue, fontSize: 12, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

// ── 라운드 카드 ──

class _RoundCard extends ConsumerWidget {
  const _RoundCard({
    required this.round,
    required this.matchId,
    required this.isExpanded,
    required this.onToggle,
  });

  final Round round;
  final String matchId;
  final bool isExpanded;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recordsAsync = ref.watch(roundRecordsProvider((matchId: matchId, roundId: round.roundId)));
    final recordCount = recordsAsync.whenOrNull(data: (r) => r.length) ?? 0;

    final statusLabel = switch (round.status) {
      RoundStatus.notStarted => '대기',
      RoundStatus.playing => 'LIVE',
      RoundStatus.finished => '종료',
      null => '대기',
    };
    final statusColor = switch (round.status) {
      RoundStatus.notStarted => _C.muted,
      RoundStatus.playing => _C.green,
      RoundStatus.finished => _C.sub,
      null => _C.muted,
    };

    return Container(
      decoration: BoxDecoration(
        color: _C.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: round.status == RoundStatus.playing ? _C.green.withValues(alpha:0.4) : _C.divider,
        ),
      ),
      child: Column(
        children: [
          GestureDetector(
            onTap: onToggle,
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Text(
                    '${round.roundIndex ?? 0}쿼터',
                    style: const TextStyle(color: _C.text, fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha:0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(statusLabel, style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.w700)),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '${round.ourScore ?? 0} - ${round.oppScore ?? 0}',
                    style: const TextStyle(color: _C.text, fontSize: 14, fontWeight: FontWeight.w800, fontFamily: 'monospace'),
                  ),
                  if (recordCount > 0) ...[
                    const SizedBox(width: 8),
                    Text(
                      '기록 $recordCount건',
                      style: const TextStyle(color: _C.muted, fontSize: 11),
                    ),
                  ],
                  const Spacer(),
                  if (round.status == RoundStatus.notStarted)
                    _RoundActionChip(
                      label: '시작',
                      color: _C.green,
                      onTap: () async {
                        final teamId = ref.read(currentTeamIdProvider);
                        if (teamId == null) return;
                        await ref.read(roundRecordDataSourceProvider).startRound(teamId, matchId, round.roundId);
                      },
                    ),
                  if (round.status == RoundStatus.playing)
                    _RoundActionChip(
                      label: '종료',
                      color: _C.gold,
                      onTap: () async {
                        final teamId = ref.read(currentTeamIdProvider);
                        if (teamId == null) return;
                        await ref.read(roundRecordDataSourceProvider).endRound(teamId, matchId, round.roundId);
                      },
                    ),
                  const SizedBox(width: 8),
                  Icon(
                    isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: _C.muted, size: 20,
                  ),
                ],
              ),
            ),
          ),
          if (isExpanded) ...[
            const Divider(color: _C.divider, height: 1),
            _RecordTimeline(matchId: matchId, roundId: round.roundId),
          ],
        ],
      ),
    );
  }
}

class _RoundActionChip extends StatelessWidget {
  const _RoundActionChip({required this.label, required this.color, required this.onTap});
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha:0.12),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: color.withValues(alpha:0.3)),
        ),
        child: Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700)),
      ),
    );
  }
}

// ── 기록 타임라인 ──

class _RecordTimeline extends ConsumerWidget {
  const _RecordTimeline({required this.matchId, required this.roundId});
  final String matchId;
  final String roundId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recordsAsync = ref.watch(
      roundRecordsProvider((matchId: matchId, roundId: roundId)),
    );

    return recordsAsync.when(
      data: (records) {
        if (records.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Center(
              child: Text('아직 기록이 없습니다', style: TextStyle(color: _C.muted, fontSize: 12)),
            ),
          );
        }
        return Padding(
          padding: const EdgeInsets.fromLTRB(14, 8, 14, 14),
          child: Column(
            children: records.map((record) => _RecordRow(record: record)).toList(),
          ),
        );
      },
      loading: () => const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator(strokeWidth: 2, color: _C.sub)),
      ),
      error: (e, _) => Padding(
        padding: const EdgeInsets.all(16),
        child: Text('$e', style: const TextStyle(color: _C.sub, fontSize: 12)),
      ),
    );
  }
}

class _RecordRow extends StatelessWidget {
  const _RecordRow({required this.record});
  final Record record;

  String _formatTime(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final (icon, iconColor, description) = switch (record) {
      GoalRecord r => (
        r.isOwnGoal == true ? Icons.sentiment_very_dissatisfied : Icons.sports_soccer,
        r.isOwnGoal == true ? _C.red : _C.green,
        _goalDescription(r),
      ),
      SubstitutionRecord r => (
        Icons.swap_horiz,
        _C.blue,
        _subDescription(r),
      ),
      _ => (Icons.circle, _C.muted, '알 수 없는 기록'),
    };

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 42,
            child: Text(
              _formatTime(record.timeOffset),
              style: TextStyle(color: _C.muted, fontSize: 11, fontWeight: FontWeight.w600, fontFamily: 'monospace'),
            ),
          ),
          Container(
            width: 24, height: 24,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha:0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 14, color: iconColor),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              description,
              style: const TextStyle(color: _C.text, fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  String _goalDescription(GoalRecord r) {
    final scorer = r.playerName ?? '미정';
    final number = r.playerNumber != null ? '#${r.playerNumber} ' : '';
    final assist = r.assistPlayerName != null ? ' (도움: ${r.assistPlayerName})' : '';
    if (r.isOwnGoal == true) return '$number$scorer 자책골';
    return '$number$scorer 득점$assist';
  }

  String _subDescription(SubstitutionRecord r) {
    final inName = r.inPlayerName ?? '?';
    final outName = r.outPlayerName ?? '?';
    final inNum = r.inPlayerNumber != null ? '#${r.inPlayerNumber} ' : '';
    final outNum = r.outPlayerNumber != null ? '#${r.outPlayerNumber} ' : '';
    return '$inNum$inName ↔ $outNum$outName';
  }
}

// ── 공통 위젯 ──

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.trailing});
  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(title, style: const TextStyle(color: _C.sub, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 1.5)),
        const Spacer(),
        if (trailing != null) trailing!,
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.icon, required this.message});
  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(
        children: [
          Icon(icon, size: 40, color: _C.muted.withValues(alpha:0.5)),
          const SizedBox(height: 12),
          Text(message, style: TextStyle(color: _C.muted, fontSize: 13)),
        ],
      ),
    );
  }
}
