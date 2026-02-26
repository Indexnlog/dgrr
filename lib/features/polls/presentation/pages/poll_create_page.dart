import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../auth/presentation/providers/auth_state_provider.dart';
import '../../../events/presentation/providers/event_providers.dart';
import '../../../../core/permissions/permission_checker.dart';
import '../../../teams/presentation/providers/current_team_provider.dart';
import '../../data/models/poll_model.dart';
import '../../domain/entities/poll.dart';
import '../../domain/services/poll_creation_service.dart';
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
}

/// 투표 생성 페이지 (운영진 전용)
/// - 월별 등록 여부 투표 (20~24일)
/// - 일자별 참석 여부 투표 (25~말일)
class PollCreatePage extends ConsumerStatefulWidget {
  const PollCreatePage({super.key});

  @override
  ConsumerState<PollCreatePage> createState() => _PollCreatePageState();
}

class _PollCreatePageState extends ConsumerState<PollCreatePage> {
  PollCategory _category = PollCategory.membership;
  String _targetMonth = PollCreationService.nextMonth();
  bool _isCreating = false;

  @override
  Widget build(BuildContext context) {
    final isAdmin = PermissionChecker.isAdmin(ref);
    final uid = ref.watch(currentUserProvider)?.uid;
    final teamId = ref.watch(currentTeamIdProvider);
    final monthParts = _targetMonth.split('-');
    final year = int.tryParse(monthParts[0]) ?? DateTime.now().year;
    final month = int.tryParse(monthParts[1]) ?? DateTime.now().month;
    final classesAsync = ref.watch(
        monthlyClassesProvider((year: year, month: month)));

    if (!isAdmin) {
      return Scaffold(
        backgroundColor: _DS.bgDeep,
        appBar: AppBar(
          backgroundColor: _DS.bgDeep,
          foregroundColor: _DS.textPrimary,
          title: const Text('투표 만들기',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
          elevation: 0,
        ),
        body: const Center(
          child: Text(
            '운영진만 투표를 생성할 수 있습니다.',
            style: TextStyle(color: _DS.textSecondary),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: _DS.bgDeep,
      appBar: AppBar(
        backgroundColor: _DS.bgDeep,
        foregroundColor: _DS.textPrimary,
        title: const Text('투표 만들기',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildSectionTitle('투표 유형'),
          const SizedBox(height: 8),
          _buildCategorySelector(),
          const SizedBox(height: 24),
          _buildSectionTitle('대상 월'),
          const SizedBox(height: 8),
          _buildMonthSelector(),
          if (_category == PollCategory.attendance) ...[
            const SizedBox(height: 24),
            _buildSectionTitle('수업 일정'),
            const SizedBox(height: 8),
            _buildClassDatesInfo(classesAsync),
          ],
          const SizedBox(height: 32),
          _buildInfoCard(),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _isCreating || uid == null || teamId == null
                  ? null
                  : () => _createPoll(context, uid, teamId, classesAsync),
              icon: _isCreating
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.add_circle_outline),
              label: Text(_isCreating ? '생성 중...' : '투표 생성'),
              style: FilledButton.styleFrom(
                backgroundColor: _DS.teamRed,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: _DS.textSecondary,
        fontSize: 13,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildCategorySelector() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: _DS.bgCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _DS.divider),
      ),
      child: Row(
        children: [
          _CategoryChip(
            label: '월별 등록',
            sublabel: '20~24일',
            isSelected: _category == PollCategory.membership,
            onTap: () => setState(() => _category = PollCategory.membership),
          ),
          const SizedBox(width: 8),
          _CategoryChip(
            label: '일자별 참석',
            sublabel: '25~말일',
            isSelected: _category == PollCategory.attendance,
            onTap: () => setState(() => _category = PollCategory.attendance),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthSelector() {
    final now = DateTime.now();
    final options = <String>[];
    for (var i = 0; i < 3; i++) {
      final d = DateTime(now.year, now.month + i);
      options.add('${d.year}-${d.month.toString().padLeft(2, '0')}');
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.map((m) {
        final parts = m.split('-');
        final label = '${parts[0]}년 ${int.parse(parts[1])}월';
        final isSelected = _targetMonth == m;
        return GestureDetector(
          onTap: () => setState(() => _targetMonth = m),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected ? _DS.gold.withOpacity(0.15) : _DS.bgCard,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isSelected ? _DS.gold : _DS.divider,
              ),
            ),
            child: Text(
              label,
              style: TextStyle(
                color: isSelected ? _DS.gold : _DS.textPrimary,
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildClassDatesInfo(AsyncValue classesAsync) {
    final monthParts = _targetMonth.split('-');
    final year = int.tryParse(monthParts[0]) ?? DateTime.now().year;
    final month = int.tryParse(monthParts[1]) ?? DateTime.now().month;

    return classesAsync.when(
      data: (classes) {
        final start = DateTime(year, month, 1);
        final end = DateTime(year, month + 1, 0);

        final inRange = classes
            .where((e) {
              final d = e.date;
              if (d == null) return false;
              final dt = DateTime.tryParse(d);
              if (dt == null) return false;
              return dt.year == year && dt.month == month;
            })
            .map((e) => e.date!)
            .toList()
          ..sort();

        if (inRange.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _DS.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _DS.divider),
            ),
            child: Text(
              '해당 월 수업 일정이 없습니다. 일정을 먼저 등록해 주세요.',
              style: TextStyle(color: _DS.textMuted, fontSize: 13),
            ),
          );
        }

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _DS.bgCard,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _DS.divider),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${inRange.length}개 수업 일정이 투표 옵션으로 포함됩니다.',
                style: const TextStyle(
                  color: _DS.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: inRange.map((d) {
                  final dt = DateTime.tryParse(d);
                  final label =
                      dt != null ? DateFormat('M/d (E)', 'ko_KR').format(dt) : d;
                  return Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: _DS.surface,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(label,
                        style: TextStyle(
                            color: _DS.textSecondary, fontSize: 12)),
                  );
                }).toList(),
              ),
            ],
          ),
        );
      },
      loading: () => const Center(
          child: Padding(
        padding: EdgeInsets.all(20),
        child: CircularProgressIndicator(strokeWidth: 2),
      )),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _DS.surface.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _DS.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, size: 18, color: _DS.textMuted),
              const SizedBox(width: 8),
              Text('등록 및 참석 투표 일정',
                  style: TextStyle(
                      color: _DS.textSecondary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '1. 월별 등록: 매월 20~24일, 다음 달 등록/휴회/미등록 선택\n'
            '2. 일자별 참석: 매월 25일~말일, 수업 참석 가능 일자 체크',
            style: TextStyle(color: _DS.textMuted, fontSize: 12, height: 1.5),
          ),
        ],
      ),
    );
  }

  Future<void> _createPoll(
    BuildContext context,
    String uid,
    String teamId,
    AsyncValue classesAsync,
  ) async {
    setState(() => _isCreating = true);
    try {
      PollModel poll;
      if (_category == PollCategory.membership) {
        poll = PollCreationService.createMembershipPoll(
          targetMonth: _targetMonth,
          createdBy: uid,
        );
      } else {
        final classDates = classesAsync.value
                ?.where((e) {
                  final d = e.date;
                  if (d == null) return false;
                  final dt = DateTime.tryParse(d);
                  if (dt == null) return false;
                  final parts = _targetMonth.split('-');
                  final y = int.tryParse(parts[0]) ?? 0;
                  final m = int.tryParse(parts[1]) ?? 0;
                  return dt.year == y && dt.month == m;
                })
                .map((e) => e.date!)
                .toList() ??
            [];
        classDates.sort();

        if (classDates.isEmpty) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text('해당 월 수업 일정이 없습니다. 먼저 등록해 주세요.')),
            );
          }
          return;
        }

        poll = PollCreationService.createAttendancePoll(
          targetMonth: _targetMonth,
          classDates: classDates,
          createdBy: uid,
        );
      }

      final pollId =
          await ref.read(pollDataSourceProvider).createPoll(teamId, poll);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('투표가 생성되었습니다.')),
        );
        context.go('/schedule/polls/$pollId');
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
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.label,
    required this.sublabel,
    required this.isSelected,
    required this.onTap,
  });
  final String label;
  final String sublabel;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
          decoration: BoxDecoration(
            color: isSelected ? _DS.gold.withOpacity(0.12) : _DS.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? _DS.gold : Colors.transparent,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? _DS.gold : _DS.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                sublabel,
                style: TextStyle(
                  color: _DS.textMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
