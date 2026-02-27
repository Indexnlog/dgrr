import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/profile_photo_uploader.dart';

import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../auth/presentation/providers/auth_state_provider.dart';
import '../../../registrations/data/models/registration_model.dart';
import '../../../registrations/domain/entities/registration.dart';
import '../../../registrations/presentation/providers/registration_providers.dart';
import '../../../registrations/presentation/widgets/monthly_registration_vote_sheet.dart';
import '../../../teams/presentation/providers/current_team_provider.dart';
import '../../../teams/presentation/providers/team_members_provider.dart';
import '../../../teams/presentation/providers/team_providers.dart';
import '../providers/my_stats_provider.dart';


class MyPage extends ConsumerWidget {
  const MyPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final stats = ref.watch(myAttendanceStatsProvider(user?.uid));
    final classStats = ref.watch(myClassStatsProvider(user?.uid));
    final regsAsync = user?.uid != null
        ? ref.watch(myRegistrationsProvider(user!.uid))
        : const AsyncValue.data(<RegistrationModel>[]);

    return Scaffold(
      backgroundColor: AppTheme.bgDeep,
      body: SafeArea(
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          children: [
            const SizedBox(height: 12),
            _buildProfileCard(context, ref, user),
            const SizedBox(height: 20),
            _buildMonthlyVoteCard(context, ref, user, regsAsync),
            const SizedBox(height: 20),
            _buildFeeStatusCard(regsAsync),
            const SizedBox(height: 20),
            if (classStats.total > 0) ...[
              _buildClassAttendanceCard(classStats),
              const SizedBox(height: 20),
            ],
            _buildAttendanceCard(stats),
            const SizedBox(height: 20),
            _buildMatchPerformanceCard(context, ref, user?.uid),
            const SizedBox(height: 20),
            _buildMenuSection(context, ref),
            const SizedBox(height: 32),
            _buildLogout(ref),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthlyVoteCard(
    BuildContext context,
    WidgetRef ref,
    dynamic user,
    AsyncValue<List<RegistrationModel>> regsAsync,
  ) {
    final seasonId = currentSeasonId;
    final seasonLabel = _formatSeason(seasonId);

    return regsAsync.when(
      data: (regs) {
        final myReg = regs
            .where((r) => r.eventId == seasonId && r.userId == user?.uid)
            .firstOrNull;

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppTheme.bgCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.divider),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.how_to_vote, color: AppTheme.textSecondary, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    '$seasonLabel 등록',
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              if (myReg != null) ...[
                Row(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.surface,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '${myReg.membershipStatus?.label ?? '-'} ${myReg.membershipStatus?.monthlyFee != null && myReg.membershipStatus!.monthlyFee > 0 ? '${myReg.membershipStatus!.monthlyFee ~/ 10000}만' : '0'}',
                              style: TextStyle(
                                color: AppTheme.textMuted,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            myReg.status == RegistrationStatus.paid ? '납부완료' : '미납',
                            style: TextStyle(
                              color: myReg.status == RegistrationStatus.paid
                                  ? AppTheme.accentGreen
                                  : AppTheme.textMuted,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isWithinRegistrationVotePeriod)
                      TextButton(
                        onPressed: () => showMonthlyRegistrationVoteSheet(context),
                        child: const Text('변경', style: TextStyle(fontSize: 13)),
                      ),
                  ],
                ),
              ] else ...[
                Text(
                  isWithinRegistrationVotePeriod
                      ? '이번 달 참가 여부를 선택해 주세요. (20~24일)'
                      : '등록 투표 기간이 아닙니다 (매월 20~24일)',
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: user?.uid != null && isWithinRegistrationVotePeriod
                        ? () => showMonthlyRegistrationVoteSheet(context)
                        : null,
                    icon: const Icon(Icons.how_to_vote, size: 18),
                    label: const Text('등록 투표하기'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppTheme.accentGreen,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildFeeStatusCard(
    AsyncValue<List<RegistrationModel>> regsAsync,
  ) {
    return regsAsync.when(
      data: (regs) {
        final feeRegs = regs
            .where((r) =>
                r.eventId.isNotEmpty &&
                r.eventId.length == 7 &&
                r.eventId.contains('-'))
            .toList();
        if (feeRegs.isEmpty) {
          return const SizedBox.shrink();
        }
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppTheme.bgCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.divider),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.payment_outlined, color: AppTheme.textSecondary, size: 18),
                  const SizedBox(width: 8),
                  const Text(
                    '회비 납부 현황',
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              ...feeRegs.map((r) {
                final fee = r.membershipStatus?.monthlyFee ?? 0;
                final isPaid = r.status == RegistrationStatus.paid;
                final seasonLabel = _formatSeason(r.eventId);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          seasonLabel,
                          style: const TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Text(
                        '${_formatFee(fee)}원',
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: isPaid
                              ? AppTheme.accentGreen.withValues(alpha:0.15)
                              : AppTheme.surface,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          isPaid ? '납부완료' : '미납',
                          style: TextStyle(
                            color: isPaid ? AppTheme.accentGreen : AppTheme.textMuted,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        );
      },
      loading: () => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.bgCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.divider),
        ),
        child: Row(
          children: [
            Icon(Icons.payment_outlined, color: AppTheme.textSecondary, size: 18),
            const SizedBox(width: 12),
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppTheme.teamRed,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              '회비 현황 로딩 중...',
              style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
            ),
          ],
        ),
      ),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  String _formatSeason(String eventId) {
    final parts = eventId.split('-');
    if (parts.length == 2) {
      return '${parts[0]}년 ${int.tryParse(parts[1]) ?? parts[1]}월';
    }
    return eventId;
  }

  String _formatFee(int fee) {
    if (fee >= 10000) {
      return '${fee ~/ 10000}만';
    }
    return fee.toString();
  }

  Widget _buildProfileCard(BuildContext context, WidgetRef ref, dynamic user) {
    final isAnonymous = user?.isAnonymous == true;
    final initial = isAnonymous
        ? 'T'
        : (user?.displayName?.isNotEmpty == true
            ? user.displayName!.substring(0, 1).toUpperCase()
            : '?');
    final memberMap = ref.watch(memberMapProvider);
    final member = user?.uid != null ? memberMap[user!.uid] : null;
    final photoUrl = member?.photoUrl ?? user?.photoURL;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Row(
        children: [
          ProfilePhotoUploader(
            radius: 28,
            photoUrl: photoUrl,
            initial: initial,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user?.displayName ?? '테스트 유저',
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  user?.email ?? '익명 로그인',
                  style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                ),
                if (member?.joinedAt != null) ...[
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      formatTenure(member!.joinedAt),
                      style: TextStyle(
                        color: AppTheme.textMuted,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClassAttendanceCard(MyClassStats stats) {
    final rate = stats.attendanceRate;
    final ratePercent = (rate * 100).toInt();
    final rateColor = rate >= 0.8
        ? AppTheme.accentGreen
        : rate >= 0.5
            ? AppTheme.gold
            : AppTheme.absentRed;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.school_outlined, color: AppTheme.textSecondary, size: 18),
              const SizedBox(width: 8),
              const Text(
                '수업 출석',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '최근 ${stats.total}수업',
                  style: TextStyle(
                    color: AppTheme.textMuted,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(
                '$ratePercent%',
                style: TextStyle(
                  color: rateColor,
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '출석률',
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: SizedBox(
                        height: 6,
                        child: LinearProgressIndicator(
                          value: rate,
                          backgroundColor: AppTheme.surface,
                          color: rateColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _StatItem(label: '참석', value: '${stats.attended}', color: AppTheme.accentGreen),
              _StatItem(label: '불참', value: '${stats.absent}', color: AppTheme.absentRed),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMatchPerformanceCard(
    BuildContext context,
    WidgetRef ref,
    String? uid,
  ) {
    if (uid == null) return const SizedBox.shrink();

    final perfAsync = ref.watch(myMatchPerformanceProvider(uid));
    return perfAsync.when(
      data: (perf) {
        if (perf.goals == 0 && perf.assists == 0) return const SizedBox.shrink();
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppTheme.bgCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.divider),
          ),
          child: Row(
            children: [
              Icon(Icons.sports_score, color: AppTheme.textSecondary, size: 18),
              const SizedBox(width: 8),
              const Text(
                '경기 활약',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              _StatItem(label: '골', value: '${perf.goals}', color: AppTheme.teamRed),
              const SizedBox(width: 16),
              _StatItem(label: '도움', value: '${perf.assists}', color: AppTheme.accentGreen),
            ],
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildAttendanceCard(MyAttendanceStats stats) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.divider),
      ),
      child: stats.total == 0
          ? _buildAttendanceEmptyState()
          : _buildAttendanceStats(stats),
    );
  }

  Widget _buildAttendanceEmptyState() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.bar_chart_rounded, color: AppTheme.textSecondary, size: 18),
            const SizedBox(width: 8),
            const Text(
              '내 출석 현황',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.sports_soccer_outlined, size: 48, color: AppTheme.textMuted.withValues(alpha: 0.5)),
              const SizedBox(height: 12),
              Text(
                '아직 완료된 경기가 없어요',
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '경기에 참석하면 출석이 기록됩니다',
                style: TextStyle(
                  color: AppTheme.textMuted,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAttendanceStats(MyAttendanceStats stats) {
    final rate = stats.attendanceRate;
    final ratePercent = (rate * 100).toInt();
    final rateColor = rate >= 0.8
        ? AppTheme.accentGreen
        : rate >= 0.5
            ? AppTheme.gold
            : AppTheme.absentRed;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.bar_chart_rounded, color: AppTheme.textSecondary, size: 18),
            const SizedBox(width: 8),
            const Text(
              '내 출석 현황',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 3,
              ),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '최근 ${stats.total}경기',
                style: TextStyle(
                  color: AppTheme.textMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // 출석률 프로그레스
        Row(
          children: [
              Text(
                '$ratePercent%',
                style: TextStyle(
                  color: rateColor,
                  fontSize: 36,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '출석률',
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: SizedBox(
                        height: 8,
                        child: LinearProgressIndicator(
                          value: rate,
                          backgroundColor: AppTheme.surface,
                          color: rateColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
        ),
        const SizedBox(height: 16),
        Container(
          height: 1,
          color: AppTheme.divider,
        ),
        const SizedBox(height: 14),
        // 상세 스탯
        Row(
            children: [
              _StatItem(
                label: '참석',
                value: '${stats.attended}',
                color: AppTheme.accentGreen,
              ),
              _StatItem(
                label: '불참',
                value: '${stats.absent}',
                color: AppTheme.absentRed,
              ),
              _StatItem(
              label: '미투표',
              value: '${stats.noVote}',
              color: AppTheme.textMuted,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMenuSection(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        _MenuItem(
          icon: Icons.payment_outlined,
          label: '회비 관리',
          onTap: () => context.push('/my/fees'),
        ),
        _MenuItem(
          icon: Icons.stadium_outlined,
          label: '구장 관리',
          subtitle: '운영진',
          onTap: () => context.push('/my/grounds'),
        ),
        _MenuItem(
          icon: Icons.menu_book_outlined,
          label: '영원FC 안내',
          subtitle: '회칙·회비·구장',
          onTap: () => context.push('/welcome'),
        ),
        _MenuItem(
          icon: Icons.privacy_tip_outlined,
          label: '개인정보처리방침',
          onTap: () => context.push('/my/privacy'),
        ),
        _MenuItem(
          icon: Icons.description_outlined,
          label: '이용약관',
          onTap: () => context.push('/my/terms'),
        ),
        _MenuItem(
          icon: Icons.notifications_outlined,
          label: '알림 설정',
          subtitle: '준비 중',
        ),
        _MenuItem(
          icon: Icons.settings_outlined,
          label: '팀 설정',
          subtitle: '운영진',
          onTap: () => context.push('/my/team-settings'),
        ),
        _MenuItem(
          icon: Icons.logout_outlined,
          label: '팀 탈퇴',
          subtitle: '주의',
          onTap: () => _showLeaveTeamDialog(context, ref),
        ),
      ],
    );
  }

  void _showLeaveTeamDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('팀 탈퇴'),
        content: const Text(
          '정말 팀을 탈퇴하시겠습니까? 탈퇴 후에는 팀 데이터에 접근할 수 없습니다.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final teamId = ref.read(currentTeamIdProvider);
              final uid = ref.read(currentUserProvider)?.uid;
              if (teamId == null || uid == null) return;
              try {
                await ref.read(teamRepositoryProvider).leaveTeam(
                      teamId: teamId,
                      memberId: uid,
                    );
                await ref.read(currentTeamIdProvider.notifier).clearTeam();
                if (context.mounted) {
                  context.go('/');
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('탈퇴 실패: $e')),
                  );
                }
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('탈퇴'),
          ),
        ],
      ),
    );
  }

  Widget _buildLogout(WidgetRef ref) {
    return GestureDetector(
      onTap: () async {
        ref.read(signOutProvider)();
        await ref.read(currentTeamIdProvider.notifier).clearTeam();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: AppTheme.bgCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.divider),
        ),
        child: const Center(
          child: Text(
            '로그아웃',
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              color: AppTheme.textMuted,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  const _MenuItem({
    required this.icon,
    required this.label,
    this.subtitle,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final String? subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppTheme.bgCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.divider),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: AppTheme.textSecondary),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (subtitle != null)
              Text(
                subtitle!,
                style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
              ),
            const SizedBox(width: 8),
            Icon(Icons.chevron_right, size: 18, color: AppTheme.textMuted),
          ],
        ),
      ),
    );
  }
}
