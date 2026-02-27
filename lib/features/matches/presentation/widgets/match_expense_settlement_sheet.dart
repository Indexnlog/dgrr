import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_state_provider.dart';
import '../../../teams/presentation/providers/current_team_provider.dart';
import '../../../teams/presentation/providers/team_members_provider.dart'
    show memberMapProvider;
import '../../../transactions/presentation/providers/transaction_providers.dart';
import '../../domain/entities/match.dart';

class _DS {
  _DS._();
  static const bgCard = Color(0xFF161B22);
  static const surface = Color(0xFF21262D);
  static const teamRed = Color(0xFFDC2626);
  static const textPrimary = Color(0xFFF0F6FC);
  static const textSecondary = Color(0xFF8B949E);
  static const gold = Color(0xFFFBBF24);
}

/// 경기 경비 정산 시트 (총무/관리자)
void showMatchExpenseSettlementSheet(
  BuildContext context, {
  required Match match,
}) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: _DS.bgCard,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) => _MatchExpenseSettlementSheet(match: match),
  );
}

class _MatchExpenseSettlementSheet extends ConsumerStatefulWidget {
  const _MatchExpenseSettlementSheet({required this.match});
  final Match match;

  @override
  ConsumerState<_MatchExpenseSettlementSheet> createState() =>
      _MatchExpenseSettlementSheetState();
}

class _MatchExpenseSettlementSheetState
    extends ConsumerState<_MatchExpenseSettlementSheet> {
  final _controller = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final amount = int.tryParse(_controller.text.replaceAll(',', ''));
    if (amount == null || amount <= 0) return;

    final teamId = ref.read(currentTeamIdProvider);
    final uid = ref.read(currentUserProvider)?.uid;
    if (teamId == null || uid == null) return;

    final attendees = widget.match.attendees ?? [];
    if (attendees.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('참석자가 없습니다')),
        );
      }
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      await ref.read(transactionDataSourceProvider).createMatchExpenseSettlement(
            teamId: teamId,
            matchId: widget.match.matchId,
            totalAmount: amount,
            attendeeUids: attendees,
            createdBy: uid,
          );
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${attendees.length}명에게 1인당 ${amount ~/ attendees.length}원 정산 등록됨',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('정산 실패: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final attendees = widget.match.attendees ?? [];
    final memberMap = ref.watch(memberMapProvider);
    final perPerson = _controller.text.isNotEmpty
        ? (int.tryParse(_controller.text.replaceAll(',', '')) ?? 0) ~/
            (attendees.isEmpty ? 1 : attendees.length)
        : 0;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              '경기 경비 정산',
              style: TextStyle(
                color: _DS.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '참석자 ${attendees.length}명에게 균등 분할',
              style: const TextStyle(
                color: _DS.textSecondary,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _controller,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: _DS.textPrimary, fontSize: 18),
              decoration: InputDecoration(
                hintText: '총 경비 (원)',
                hintStyle: TextStyle(color: _DS.textSecondary.withValues(alpha: 0.6)),
                filled: true,
                fillColor: _DS.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (_) => setState(() {}),
            ),
            if (perPerson > 0) ...[
              const SizedBox(height: 12),
              Text(
                '1인당 $perPerson원',
                style: const TextStyle(
                  color: _DS.gold,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
            const SizedBox(height: 16),
            if (attendees.isNotEmpty)
              Text(
                '참석자: ${attendees.map((u) => memberMap[u]?.uniformName ?? memberMap[u]?.name ?? u.substring(0, 4)).join(', ')}',
                style: const TextStyle(
                  color: _DS.textSecondary,
                  fontSize: 12,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _isSubmitting ? null : _submit,
              style: FilledButton.styleFrom(
                backgroundColor: _DS.teamRed,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: Text(_isSubmitting ? '처리 중...' : '정산 등록'),
            ),
          ],
        ),
      ),
    );
  }
}
