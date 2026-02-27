import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/errors.dart';
import '../../../auth/presentation/providers/auth_state_provider.dart';
import '../../../teams/domain/entities/member.dart';
import '../../../teams/presentation/providers/current_team_provider.dart';
import '../../../teams/presentation/providers/team_members_provider.dart';
import '../../domain/entities/registration.dart';
import '../providers/registration_providers.dart';

/// 월간 등록 투표 바텀시트 (등록 5만 / 휴회 2만 / 미등록 0원)
Future<void> showMonthlyRegistrationVoteSheet(BuildContext context) async {
  await showModalBottomSheet<void>(
    context: context,
    backgroundColor: _C.card,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (ctx) => const _MonthlyRegistrationVoteSheet(),
  );
}

class _C {
  _C._();
  static const card = Color(0xFF161B22);
  static const surface = Color(0xFF21262D);
  static const green = Color(0xFF2EA043);
  static const gold = Color(0xFFFBBF24);
  static const text = Color(0xFFF0F6FC);
  static const sub = Color(0xFF8B949E);
  static const muted = Color(0xFF484F58);
  static const divider = Color(0xFF30363D);
}

class _MonthlyRegistrationVoteSheet extends ConsumerWidget {
  const _MonthlyRegistrationVoteSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final members = ref.watch(teamMembersProvider).value ?? [];
    final Member? member = user?.uid != null
        ? members.where((m) => m.memberId == user!.uid).firstOrNull
        : null;
    final seasonLabel = _formatSeason(currentSeasonId);

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: _C.muted,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Icon(Icons.how_to_vote, color: _C.green, size: 22),
              const SizedBox(width: 8),
              Text(
                '$seasonLabel 등록 투표',
                style: const TextStyle(
                  color: _C.text,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '이번 달 참가 여부를 선택해 주세요. 총무가 결제 확인 후 납부 완료 처리됩니다.',
            style: TextStyle(color: _C.sub, fontSize: 13),
          ),
          const SizedBox(height: 24),
          ...MembershipStatus.values.map((status) => _VoteOption(
                status: status,
                onTap: () {
                  HapticFeedback.lightImpact();
                  _submitVote(context, ref, status, user, member);
                },
              )),
        ],
      ),
    );
  }

  String _formatSeason(String seasonId) {
    final parts = seasonId.split('-');
    if (parts.length == 2) {
      return '${parts[0]}년 ${int.tryParse(parts[1]) ?? parts[1]}월';
    }
    return seasonId;
  }

  Future<void> _submitVote(
    BuildContext context,
    WidgetRef ref,
    MembershipStatus status,
    dynamic user,
    Member? member,
  ) async {
    final teamId = ref.read(currentTeamIdProvider);
    if (teamId == null || user?.uid == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('로그인이 필요합니다')),
        );
      }
      return;
    }

    try {
      await ref.read(registrationDataSourceProvider).upsertMembershipRegistration(
            teamId: teamId,
            seasonId: currentSeasonId,
            userId: user.uid,
            membershipStatus: status,
            userName: member?.name ?? user.displayName,
            uniformNo: member?.number,
            photoUrl: member?.photoUrl ?? user.photoURL,
          );
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${status.label} (${status.monthlyFee > 0 ? '${status.monthlyFee ~/ 10000}만원' : '0원'})로 등록되었습니다'),
            backgroundColor: _C.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ErrorHandler.showError(context, e, fallback: '저장에 실패했습니다');
      }
    }
  }
}

class _VoteOption extends StatelessWidget {
  const _VoteOption({
    required this.status,
    required this.onTap,
  });

  final MembershipStatus status;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final fee = status.monthlyFee;
    final feeText = fee >= 10000 ? '${fee ~/ 10000}만원' : '$fee원';

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: _C.surface,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _C.divider),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    status.label,
                    style: const TextStyle(
                      color: _C.text,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Text(
                  feeText,
                  style: TextStyle(
                    color: fee > 0 ? _C.gold : _C.sub,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 8),
                Icon(Icons.chevron_right, color: _C.muted, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
