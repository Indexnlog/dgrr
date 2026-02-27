import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../registrations/data/models/registration_model.dart';
import '../../../registrations/domain/entities/registration.dart';
import '../../../registrations/presentation/providers/registration_providers.dart';
import '../../../teams/domain/entities/member.dart';
import '../../../teams/presentation/providers/current_team_provider.dart';
import '../../../teams/presentation/providers/team_members_provider.dart';
import '../../../teams/presentation/providers/user_role_provider.dart';
import '../../domain/entities/fee.dart';
import '../providers/fee_providers.dart';
import '../widgets/fee_create_sheet.dart';

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
  static const gold = Color(0xFFFBBF24);
  static const divider = Color(0xFF30363D);
}

class FeeManagementPage extends ConsumerWidget {
  const FeeManagementPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feesAsync = ref.watch(allFeesProvider);

    return Scaffold(
      backgroundColor: _DS.bgDeep,
      appBar: AppBar(
        backgroundColor: _DS.bgDeep,
        foregroundColor: _DS.textPrimary,
        title: const Text('회비 관리',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
        elevation: 0,
        actions: [
          if (ref.watch(hasPermissionProvider(Permission.treasurer)))
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () => showFeeCreateSheet(context),
            ),
        ],
      ),
      body: feesAsync.when(
        data: (fees) {
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              _CurrentMonthRegistrationCard(),
              if (fees.isEmpty) ...[
                const SizedBox(height: 20),
                Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.account_balance_wallet_outlined,
                      size: 48, color: _DS.textMuted.withValues(alpha:0.4)),
                  const SizedBox(height: 12),
                  Text('회비 설정이 없습니다',
                      style: TextStyle(color: _DS.textMuted, fontSize: 14)),
                ],
              ),
            ),
          ] else ...[
                const SizedBox(height: 12),
                ...fees.map((f) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _FeeCard(fee: f),
                )),
              ],
            ],
          );
        },
        loading: () => const Center(
            child: CircularProgressIndicator(
                color: _DS.teamRed, strokeWidth: 2.5)),
        error: (e, _) => Center(
            child: Text('오류: $e',
                style: const TextStyle(color: _DS.textSecondary))),
      ),
    );
  }
}

/// 이번 달 월간 등록 현황 (총무 결제 확인용)
class _CurrentMonthRegistrationCard extends ConsumerWidget {
  const _CurrentMonthRegistrationCard();

  static String _formatSeason(String id) {
    final parts = id.split('-');
    if (parts.length == 2) {
      return '${parts[0]}년 ${int.tryParse(parts[1]) ?? parts[1]}월';
    }
    return id;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final regsAsync = ref.watch(currentMonthRegistrationsProvider);
    final memberMap = ref.watch(memberMapProvider);
    final teamId = ref.watch(currentTeamIdProvider) ?? '';
    final seasonLabel = _formatSeason(currentSeasonId);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _DS.bgCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _DS.attendGreen.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _DS.attendGreen.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text('이번 달',
                    style: TextStyle(
                        color: _DS.attendGreen,
                        fontSize: 11,
                        fontWeight: FontWeight.w700)),
              ),
              const SizedBox(width: 8),
              Text(seasonLabel,
                  style: const TextStyle(
                      color: _DS.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 14),
          regsAsync.when(
            data: (regs) => _PaymentStatus(
              registrations: regs,
              memberMap: memberMap,
              teamId: teamId,
              feeId: currentSeasonId,
              ref: ref,
            ),
            loading: () => const SizedBox(
              height: 24,
              child: Center(
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: _DS.textMuted),
              ),
            ),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

class _FeeCard extends ConsumerWidget {
  const _FeeCard({required this.fee});
  final Fee fee;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final regsAsync = ref.watch(seasonRegistrationsProvider(fee.feeId));
    final memberMap = ref.watch(memberMapProvider);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _DS.bgCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _DS.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: fee.isActive == true
                      ? _DS.attendGreen.withValues(alpha:0.15)
                      : _DS.surface,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(fee.isActive == true ? '활성' : '비활성',
                    style: TextStyle(
                        color: fee.isActive == true
                            ? _DS.attendGreen
                            : _DS.textMuted,
                        fontSize: 11,
                        fontWeight: FontWeight.w700)),
              ),
              const Spacer(),
              Text('${fee.amount ?? 0}원',
                  style: const TextStyle(
                      color: _DS.gold,
                      fontSize: 16,
                      fontWeight: FontWeight.w800)),
            ],
          ),
          const SizedBox(height: 10),
          Text(fee.name ?? fee.feeType.value,
              style: const TextStyle(
                  color: _DS.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w700)),
          if (fee.memo != null) ...[
            const SizedBox(height: 4),
            Text(fee.memo!,
                style:
                    TextStyle(color: _DS.textSecondary, fontSize: 13)),
          ],
          const Divider(color: _DS.divider, height: 24),
          // 납부 현황
          regsAsync.when(
            data: (regs) => _PaymentStatus(
              registrations: regs,
              memberMap: memberMap,
              teamId: ref.watch(currentTeamIdProvider) ?? '',
              feeId: fee.feeId,
              ref: ref,
            ),
            loading: () => const SizedBox(
              height: 24,
              child: Center(
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: _DS.textMuted)),
            ),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

void _showUnpaidListDialog(
  BuildContext context,
  List<RegistrationModel> unpaid,
) {
  if (unpaid.isEmpty) return;
  showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: _DS.bgCard,
      title: Text(
        '미납자 목록 (${unpaid.length}명)',
        style: const TextStyle(color: _DS.textPrimary, fontSize: 18),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: unpaid
              .map((r) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      r.userName ?? '알 수 없음',
                      style: const TextStyle(
                        color: _DS.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                  ))
              .toList(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('닫기', style: TextStyle(color: _DS.gold)),
        ),
      ],
    ),
  );
}

class _PaymentStatus extends StatelessWidget {
  const _PaymentStatus({
    required this.registrations,
    required this.memberMap,
    required this.teamId,
    required this.feeId,
    required this.ref,
  });

  final List<RegistrationModel> registrations;
  final Map<String, Member> memberMap;
  final String teamId;
  final String feeId;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    final paid = registrations
        .where((r) => r.status == RegistrationStatus.paid)
        .length;
    final total = registrations.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('납부 현황',
                style: TextStyle(
                    color: _DS.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600)),
            const Spacer(),
            if (total > paid)
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: GestureDetector(
                  onTap: () {
                    final unpaid = registrations
                        .where((r) => r.status != RegistrationStatus.paid)
                        .toList();
                    _showUnpaidListDialog(context, unpaid);
                    // TODO: Cloud Function sendNudgeToUnpaid 연동 시 푸시 발송
                    // docs/FCM_NUDGE_연동가이드.md 참고
                  },
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.notifications_active_outlined,
                          size: 14, color: _DS.gold),
                      const SizedBox(width: 4),
                      Text('미납자 알림',
                          style: TextStyle(
                              color: _DS.gold,
                              fontSize: 11,
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ),
            Text('$paid / $total',
                style: TextStyle(
                    color: paid == total ? _DS.attendGreen : _DS.gold,
                    fontSize: 13,
                    fontWeight: FontWeight.w700)),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: SizedBox(
            height: 6,
            child: LinearProgressIndicator(
              value: total > 0 ? paid / total : 0.0,
              backgroundColor: _DS.surface,
              color: _DS.attendGreen,
            ),
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: registrations.map((reg) {
            final isPaid = reg.status == RegistrationStatus.paid;
            return GestureDetector(
              onTap: () async {
                final newStatus = isPaid ? 'pending' : 'paid';
                await ref
                    .read(registrationDataSourceProvider)
                    .updatePaymentStatus(teamId, reg.registrationId, newStatus);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: isPaid
                      ? _DS.attendGreen.withValues(alpha:0.1)
                      : _DS.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: isPaid
                          ? _DS.attendGreen.withValues(alpha:0.3)
                          : _DS.divider),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                        isPaid
                            ? Icons.check_circle
                            : Icons.radio_button_unchecked,
                        size: 14,
                        color: isPaid ? _DS.attendGreen : _DS.textMuted),
                    const SizedBox(width: 4),
                    Text(reg.userName ?? '알 수 없음',
                        style: TextStyle(
                            color: isPaid
                                ? _DS.textPrimary
                                : _DS.textSecondary,
                            fontSize: 12,
                            fontWeight: FontWeight.w500)),
                    if (reg.membershipStatus != null) ...[
                      const SizedBox(width: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 4, vertical: 1),
                        decoration: BoxDecoration(
                          color: _DS.surface,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '${reg.membershipStatus!.label} ${reg.membershipStatus!.monthlyFee > 0 ? '${reg.membershipStatus!.monthlyFee ~/ 10000}만' : '0'}',
                          style: TextStyle(
                            color: _DS.textMuted,
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
