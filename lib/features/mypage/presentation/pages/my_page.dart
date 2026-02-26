import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';

import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../auth/presentation/providers/auth_state_provider.dart';
import '../../../registrations/data/models/registration_model.dart';
import '../../../registrations/domain/entities/registration.dart';
import '../../../registrations/presentation/providers/registration_providers.dart';
import '../../../teams/presentation/providers/current_team_provider.dart';
import '../providers/my_stats_provider.dart';


class MyPage extends ConsumerWidget {
  const MyPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final stats = ref.watch(myAttendanceStatsProvider(user?.uid));
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
            _buildProfileCard(user),
            const SizedBox(height: 20),
            _buildFeeStatusCard(regsAsync),
            const SizedBox(height: 20),
            _buildAttendanceCard(stats),
            const SizedBox(height: 20),
            _buildMenuSection(context),
            const SizedBox(height: 32),
            _buildLogout(ref),
          ],
        ),
      ),
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
                              ? AppTheme.accentGreen.withOpacity(0.15)
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

  Widget _buildProfileCard(dynamic user) {
    final isAnonymous = user?.isAnonymous == true;
    final initial = isAnonymous
        ? 'T'
        : (user?.displayName?.substring(0, 1) ?? '?');

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: AppTheme.teamRed.withOpacity(0.2),
            child: Text(
              initial,
              style: const TextStyle(
                color: AppTheme.teamRed,
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
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
              ],
            ),
          ),
          Icon(Icons.edit_outlined, color: AppTheme.textMuted, size: 20),
        ],
      ),
    );
  }

  Widget _buildAttendanceCard(MyAttendanceStats stats) {
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
      ),
    );
  }

  Widget _buildMenuSection(BuildContext context) {
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
          icon: Icons.article_outlined,
          label: '공식 문서',
          subtitle: '준비 중',
        ),
        _MenuItem(
          icon: Icons.notifications_outlined,
          label: '알림 설정',
          subtitle: '준비 중',
        ),
        _MenuItem(
          icon: Icons.settings_outlined,
          label: '설정',
          subtitle: '준비 중',
        ),
      ],
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
