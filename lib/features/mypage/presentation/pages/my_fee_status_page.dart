import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../auth/presentation/providers/auth_state_provider.dart';
import '../../../registrations/data/models/registration_model.dart';
import '../../../registrations/domain/entities/registration.dart';
import '../../../registrations/presentation/providers/registration_providers.dart';

/// 내 회비 납부 현황 페이지
class MyFeeStatusPage extends ConsumerWidget {
  const MyFeeStatusPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uid = ref.watch(currentUserProvider)?.uid;
    final regsAsync = uid == null
        ? const AsyncValue.data(<RegistrationModel>[])
        : ref.watch(myRegistrationsProvider(uid));

    return Scaffold(
      backgroundColor: AppTheme.bgDeep,
      appBar: AppBar(
        backgroundColor: AppTheme.bgDeep,
        foregroundColor: AppTheme.textPrimary,
        elevation: 0,
        title: const Text(
          '내 회비 현황',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
        ),
      ),
      body: regsAsync.when(
        data: (regs) {
          final feeRegs =
              regs
                  .where(
                    (r) =>
                        r.eventId.isNotEmpty &&
                        r.eventId.length == 7 &&
                        r.eventId.contains('-'),
                  )
                  .toList()
                ..sort((a, b) => b.eventId.compareTo(a.eventId));

          final currentReg = feeRegs
              .where((r) => r.eventId == currentSeasonId)
              .firstOrNull;

          return RefreshIndicator(
            color: AppTheme.teamRed,
            onRefresh: () async {
              if (uid != null) {
                ref.invalidate(myRegistrationsProvider(uid));
              }
            },
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
              children: [
                _CurrentMonthFeeCard(reg: currentReg),
                const SizedBox(height: 16),
                if (feeRegs.isEmpty)
                  _EmptyFeeHistoryCard()
                else
                  _FeeHistoryCard(registrations: feeRegs),
              ],
            ),
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(
            color: AppTheme.teamRed,
            strokeWidth: 2.5,
          ),
        ),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              '회비 정보를 불러오지 못했어요\n$e',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 14,
                height: 1.5,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CurrentMonthFeeCard extends StatelessWidget {
  const _CurrentMonthFeeCard({required this.reg});
  final RegistrationModel? reg;

  @override
  Widget build(BuildContext context) {
    final isPaid = reg?.status == RegistrationStatus.paid;
    final fee = reg?.membershipStatus?.monthlyFee ?? 0;

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
              Icon(
                Icons.calendar_month,
                color: AppTheme.textSecondary,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                '${_formatSeason(currentSeasonId)} 회비',
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (reg == null) ...[
            Text(
              '아직 이번 달 등록 정보가 없습니다',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
            ),
          ] else ...[
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${_formatFee(fee)}원',
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: isPaid
                        ? AppTheme.accentGreen.withValues(alpha: 0.15)
                        : AppTheme.surface,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    isPaid ? '납부완료' : '미납',
                    style: TextStyle(
                      color: isPaid ? AppTheme.accentGreen : AppTheme.textMuted,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _FeeHistoryCard extends StatelessWidget {
  const _FeeHistoryCard({required this.registrations});
  final List<RegistrationModel> registrations;

  @override
  Widget build(BuildContext context) {
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
              Icon(Icons.history, color: AppTheme.textSecondary, size: 18),
              const SizedBox(width: 8),
              const Text(
                '월별 납부 이력',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...registrations.map((reg) {
            final isPaid = reg.status == RegistrationStatus.paid;
            final fee = reg.membershipStatus?.monthlyFee ?? 0;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _formatSeason(reg.eventId),
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${_formatFee(fee)}원',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: isPaid
                          ? AppTheme.accentGreen.withValues(alpha: 0.15)
                          : AppTheme.surface,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      isPaid ? '납부완료' : '미납',
                      style: TextStyle(
                        color: isPaid
                            ? AppTheme.accentGreen
                            : AppTheme.textMuted,
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
  }
}

class _EmptyFeeHistoryCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Column(
        children: [
          Icon(
            Icons.receipt_long_outlined,
            color: AppTheme.textMuted.withValues(alpha: 0.6),
            size: 40,
          ),
          const SizedBox(height: 10),
          Text(
            '회비 납부 이력이 없습니다',
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
          ),
        ],
      ),
    );
  }
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
