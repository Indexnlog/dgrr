import 'package:flutter/material.dart';

import '../../../teams/domain/entities/member.dart';
import '../../data/datasources/round_record_data_source.dart';
import '../../domain/entities/record.dart';

class _C {
  _C._();
  static const card = Color(0xFF161B22);
  static const surface = Color(0xFF21262D);
  static const green = Color(0xFF2EA043);
  static const blue = Color(0xFF58A6FF);
  static const text = Color(0xFFF0F6FC);
  static const sub = Color(0xFF8B949E);
  static const muted = Color(0xFF484F58);
  static const divider = Color(0xFF30363D);
}

/// 득점 기록 모달
Future<void> showGoalRecordModal({
  required BuildContext context,
  required String teamId,
  required String matchId,
  required String roundId,
  required List<Member> members,
  required int elapsedSeconds,
  required RoundRecordDataSource dataSource,
  String? createdBy,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: _C.card,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (ctx) => _GoalRecordSheet(
      teamId: teamId,
      matchId: matchId,
      roundId: roundId,
      members: members,
      elapsedSeconds: elapsedSeconds,
      dataSource: dataSource,
      createdBy: createdBy,
    ),
  );
}

class _GoalRecordSheet extends StatefulWidget {
  const _GoalRecordSheet({
    required this.teamId,
    required this.matchId,
    required this.roundId,
    required this.members,
    required this.elapsedSeconds,
    required this.dataSource,
    this.createdBy,
  });

  final String teamId, matchId, roundId;
  final List<Member> members;
  final int elapsedSeconds;
  final RoundRecordDataSource dataSource;
  final String? createdBy;

  @override
  State<_GoalRecordSheet> createState() => _GoalRecordSheetState();
}

class _GoalRecordSheetState extends State<_GoalRecordSheet> {
  Member? _scorer;
  Member? _assister;
  TeamType _teamType = TeamType.our;
  String _goalType = '일반';
  bool _isOwnGoal = false;
  bool _isSaving = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20, right: 20, top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(width: 40, height: 4, decoration: BoxDecoration(color: _C.muted, borderRadius: BorderRadius.circular(2))),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(Icons.sports_soccer, color: _C.green, size: 22),
              const SizedBox(width: 8),
              const Text('득점 기록', style: TextStyle(color: _C.text, fontSize: 18, fontWeight: FontWeight.w700)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: _C.surface, borderRadius: BorderRadius.circular(6)),
                child: Text(
                  _formatTime(widget.elapsedSeconds),
                  style: const TextStyle(color: _C.sub, fontSize: 12, fontWeight: FontWeight.w600, fontFamily: 'monospace'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // 팀 선택
          _Label('팀'),
          const SizedBox(height: 6),
          Row(
            children: [
              _ChoiceChip(label: '우리 팀', selected: _teamType == TeamType.our, onTap: () => setState(() => _teamType = TeamType.our)),
              const SizedBox(width: 8),
              _ChoiceChip(label: '상대 팀', selected: _teamType == TeamType.opponent, onTap: () => setState(() => _teamType = TeamType.opponent)),
            ],
          ),
          const SizedBox(height: 16),

          // 득점자 선택
          _Label('득점자'),
          const SizedBox(height: 6),
          _PlayerDropdown(
            members: widget.members,
            selected: _scorer,
            hint: '선수 선택',
            onChanged: (m) => setState(() => _scorer = m),
          ),
          const SizedBox(height: 16),

          // 도움 선택
          _Label('도움 (선택)'),
          const SizedBox(height: 6),
          _PlayerDropdown(
            members: widget.members,
            selected: _assister,
            hint: '없음',
            onChanged: (m) => setState(() => _assister = m),
            allowNone: true,
          ),
          const SizedBox(height: 16),

          // 득점 유형
          _Label('유형'),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            children: ['일반', 'PK', '프리킥', '자책골'].map((type) {
              final selected = type == '자책골' ? _isOwnGoal : (_goalType == type && !_isOwnGoal);
              return _ChoiceChip(
                label: type,
                selected: selected,
                onTap: () => setState(() {
                  if (type == '자책골') {
                    _isOwnGoal = !_isOwnGoal;
                    if (_isOwnGoal) _goalType = '자책골';
                  } else {
                    _isOwnGoal = false;
                    _goalType = type;
                  }
                }),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),

          // 저장 버튼
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _C.green,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: _isSaving ? null : _save,
              child: _isSaving
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('기록 저장', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    try {
      await widget.dataSource.addGoalRecord(
        teamId: widget.teamId,
        matchId: widget.matchId,
        roundId: widget.roundId,
        teamType: _teamType,
        timeOffset: widget.elapsedSeconds,
        playerId: _scorer?.memberId,
        playerName: _scorer?.uniformName ?? _scorer?.name,
        playerNumber: _scorer?.number,
        assistPlayerId: _assister?.memberId,
        assistPlayerName: _assister?.uniformName ?? _assister?.name,
        goalType: _goalType,
        isOwnGoal: _isOwnGoal,
        createdBy: widget.createdBy,
      );
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('득점 기록되었습니다'), backgroundColor: _C.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('저장 실패: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  String _formatTime(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}

/// 교체 기록 모달
Future<void> showSubstitutionRecordModal({
  required BuildContext context,
  required String teamId,
  required String matchId,
  required String roundId,
  required List<Member> members,
  required int elapsedSeconds,
  required RoundRecordDataSource dataSource,
  String? createdBy,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: _C.card,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (ctx) => _SubstitutionRecordSheet(
      teamId: teamId,
      matchId: matchId,
      roundId: roundId,
      members: members,
      elapsedSeconds: elapsedSeconds,
      dataSource: dataSource,
      createdBy: createdBy,
    ),
  );
}

class _SubstitutionRecordSheet extends StatefulWidget {
  const _SubstitutionRecordSheet({
    required this.teamId,
    required this.matchId,
    required this.roundId,
    required this.members,
    required this.elapsedSeconds,
    required this.dataSource,
    this.createdBy,
  });

  final String teamId, matchId, roundId;
  final List<Member> members;
  final int elapsedSeconds;
  final RoundRecordDataSource dataSource;
  final String? createdBy;

  @override
  State<_SubstitutionRecordSheet> createState() => _SubstitutionRecordSheetState();
}

class _SubstitutionRecordSheetState extends State<_SubstitutionRecordSheet> {
  Member? _inPlayer;
  Member? _outPlayer;
  bool _isSaving = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20, right: 20, top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(width: 40, height: 4, decoration: BoxDecoration(color: _C.muted, borderRadius: BorderRadius.circular(2))),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(Icons.swap_horiz, color: _C.blue, size: 22),
              const SizedBox(width: 8),
              const Text('교체 기록', style: TextStyle(color: _C.text, fontSize: 18, fontWeight: FontWeight.w700)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: _C.surface, borderRadius: BorderRadius.circular(6)),
                child: Text(
                  _formatTime(widget.elapsedSeconds),
                  style: const TextStyle(color: _C.sub, fontSize: 12, fontWeight: FontWeight.w600, fontFamily: 'monospace'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // OUT 선수
          _Label('OUT (나가는 선수)'),
          const SizedBox(height: 6),
          _PlayerDropdown(
            members: widget.members,
            selected: _outPlayer,
            hint: '선수 선택',
            onChanged: (m) => setState(() => _outPlayer = m),
          ),
          const SizedBox(height: 20),

          Center(
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _C.blue.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.swap_vert, color: _C.blue, size: 20),
            ),
          ),
          const SizedBox(height: 20),

          // IN 선수
          _Label('IN (들어오는 선수)'),
          const SizedBox(height: 6),
          _PlayerDropdown(
            members: widget.members,
            selected: _inPlayer,
            hint: '선수 선택',
            onChanged: (m) => setState(() => _inPlayer = m),
          ),
          const SizedBox(height: 24),

          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _C.blue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: (_isSaving || _inPlayer == null || _outPlayer == null) ? null : _save,
              child: _isSaving
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('기록 저장', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    try {
      await widget.dataSource.addSubstitutionRecord(
        teamId: widget.teamId,
        matchId: widget.matchId,
        roundId: widget.roundId,
        teamType: TeamType.our,
        timeOffset: widget.elapsedSeconds,
        inPlayerId: _inPlayer?.memberId,
        inPlayerName: _inPlayer?.uniformName ?? _inPlayer?.name,
        inPlayerNumber: _inPlayer?.number,
        outPlayerId: _outPlayer?.memberId,
        outPlayerName: _outPlayer?.uniformName ?? _outPlayer?.name,
        outPlayerNumber: _outPlayer?.number,
        createdBy: widget.createdBy,
      );
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('교체 기록되었습니다'), backgroundColor: _C.blue),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('저장 실패: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  String _formatTime(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}

// ── 공용 위젯 ──

class _Label extends StatelessWidget {
  const _Label(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(text, style: const TextStyle(color: _C.sub, fontSize: 12, fontWeight: FontWeight.w600));
  }
}

class _ChoiceChip extends StatelessWidget {
  const _ChoiceChip({required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? _C.green.withOpacity(0.15) : _C.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? _C.green : _C.divider,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? _C.green : _C.sub,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

/// 빠른 골 기록 (1탭)
Future<void> showQuickGoalSheet({
  required BuildContext context,
  required String teamId,
  required String matchId,
  required String roundId,
  required List<Member> members,
  required int elapsedSeconds,
  required RoundRecordDataSource dataSource,
  String? createdBy,
}) {
  return showModalBottomSheet(
    context: context,
    backgroundColor: _C.card,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (ctx) => _QuickGoalSheet(
      teamId: teamId,
      matchId: matchId,
      roundId: roundId,
      members: members,
      elapsedSeconds: elapsedSeconds,
      dataSource: dataSource,
      createdBy: createdBy,
    ),
  );
}

class _QuickGoalSheet extends StatelessWidget {
  const _QuickGoalSheet({
    required this.teamId,
    required this.matchId,
    required this.roundId,
    required this.members,
    required this.elapsedSeconds,
    required this.dataSource,
    this.createdBy,
  });

  final String teamId, matchId, roundId;
  final List<Member> members;
  final int elapsedSeconds;
  final RoundRecordDataSource dataSource;
  final String? createdBy;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20, right: 20, top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(color: _C.muted, borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 16),
          const Row(
            children: [
              Icon(Icons.sports_soccer, color: _C.green, size: 22),
              SizedBox(width: 8),
              Text('득점자 탭', style: TextStyle(color: _C.text, fontSize: 18, fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '우리 팀 골',
            style: TextStyle(color: _C.sub, fontSize: 12),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: members.map((m) => _PlayerChip(
              member: m,
              onTap: () => _recordGoal(context, m),
            )).toList(),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Future<void> _recordGoal(BuildContext context, Member scorer) async {
    try {
      await dataSource.addGoalRecord(
        teamId: teamId,
        matchId: matchId,
        roundId: roundId,
        teamType: TeamType.our,
        timeOffset: elapsedSeconds,
        playerId: scorer.memberId,
        playerName: scorer.uniformName ?? scorer.name,
        playerNumber: scorer.number,
        createdBy: createdBy,
      );
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${scorer.name} 골!'), backgroundColor: _C.green),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('저장 실패: $e')),
        );
      }
    }
  }
}

/// 빠른 교체 기록 (OUT 1탭 → IN 1탭)
Future<void> showQuickSubstitutionSheet({
  required BuildContext context,
  required String teamId,
  required String matchId,
  required String roundId,
  required List<Member> fieldMembers,
  required List<Member> benchMembers,
  required int elapsedSeconds,
  required RoundRecordDataSource dataSource,
  String? createdBy,
}) {
  return showModalBottomSheet(
    context: context,
    backgroundColor: _C.card,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (ctx) => _QuickSubstitutionSheet(
      teamId: teamId,
      matchId: matchId,
      roundId: roundId,
      fieldMembers: fieldMembers,
      benchMembers: benchMembers,
      elapsedSeconds: elapsedSeconds,
      dataSource: dataSource,
      createdBy: createdBy,
    ),
  );
}

class _QuickSubstitutionSheet extends StatefulWidget {
  const _QuickSubstitutionSheet({
    required this.teamId,
    required this.matchId,
    required this.roundId,
    required this.fieldMembers,
    required this.benchMembers,
    required this.elapsedSeconds,
    required this.dataSource,
    this.createdBy,
  });

  final String teamId, matchId, roundId;
  final List<Member> fieldMembers;
  final List<Member> benchMembers;
  final int elapsedSeconds;
  final RoundRecordDataSource dataSource;
  final String? createdBy;

  @override
  State<_QuickSubstitutionSheet> createState() => _QuickSubstitutionSheetState();
}

class _QuickSubstitutionSheetState extends State<_QuickSubstitutionSheet> {
  Member? _outPlayer;
  Member? _inPlayer;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20, right: 20, top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(color: _C.muted, borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 16),
          const Row(
            children: [
              Icon(Icons.swap_horiz, color: _C.blue, size: 22),
              SizedBox(width: 8),
              Text('교체 빠른 기록', style: TextStyle(color: _C.text, fontSize: 18, fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 20),
          const Text('OUT (나가는 선수)', style: TextStyle(color: _C.sub, fontSize: 12, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: widget.fieldMembers.map((m) => _PlayerChip(
              member: m,
              selected: _outPlayer?.memberId == m.memberId,
              onTap: () => setState(() => _outPlayer = _outPlayer?.memberId == m.memberId ? null : m),
            )).toList(),
          ),
          const SizedBox(height: 16),
          const Text('IN (들어오는 선수)', style: TextStyle(color: _C.sub, fontSize: 12, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: widget.benchMembers.map((m) => _PlayerChip(
              member: m,
              selected: _inPlayer?.memberId == m.memberId,
              onTap: () => setState(() => _inPlayer = _inPlayer?.memberId == m.memberId ? null : m),
            )).toList(),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _C.blue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: (_outPlayer != null && _inPlayer != null) ? () => _save(context) : null,
              child: const Text('교체 기록', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Future<void> _save(BuildContext context) async {
    try {
      await widget.dataSource.addSubstitutionRecord(
        teamId: widget.teamId,
        matchId: widget.matchId,
        roundId: widget.roundId,
        teamType: TeamType.our,
        timeOffset: widget.elapsedSeconds,
        inPlayerId: _inPlayer?.memberId,
        inPlayerName: _inPlayer?.uniformName ?? _inPlayer?.name,
        inPlayerNumber: _inPlayer?.number,
        outPlayerId: _outPlayer?.memberId,
        outPlayerName: _outPlayer?.uniformName ?? _outPlayer?.name,
        outPlayerNumber: _outPlayer?.number,
        createdBy: widget.createdBy,
      );
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${_outPlayer!.name} ↔ ${_inPlayer!.name} 교체'), backgroundColor: _C.blue),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('저장 실패: $e')),
        );
      }
    }
  }
}

class _PlayerChip extends StatelessWidget {
  const _PlayerChip({required this.member, required this.onTap, this.selected = false});
  final Member member;
  final VoidCallback onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? _C.blue.withOpacity(0.2) : _C.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? _C.blue : _C.divider,
          ),
        ),
        child: Text(
          '${member.number != null ? "${member.number}번 " : ""}${member.uniformName ?? member.name}',
          style: TextStyle(
            color: selected ? _C.blue : _C.text,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _PlayerDropdown extends StatelessWidget {
  const _PlayerDropdown({
    required this.members,
    required this.selected,
    required this.hint,
    required this.onChanged,
    this.allowNone = false,
  });

  final List<Member> members;
  final Member? selected;
  final String hint;
  final ValueChanged<Member?> onChanged;
  final bool allowNone;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: _C.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _C.divider),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          value: selected?.memberId,
          hint: Text(hint, style: const TextStyle(color: _C.muted, fontSize: 14)),
          dropdownColor: _C.card,
          style: const TextStyle(color: _C.text, fontSize: 14),
          items: [
            if (allowNone)
              const DropdownMenuItem(value: '__none__', child: Text('없음', style: TextStyle(color: _C.muted))),
            ...members.map((m) => DropdownMenuItem(
              value: m.memberId,
              child: Text(
                '${m.number != null ? '#${m.number} ' : ''}${m.uniformName ?? m.name}',
                style: const TextStyle(color: _C.text),
              ),
            )),
          ],
          onChanged: (id) {
            if (id == '__none__') {
              onChanged(null);
            } else {
              final member = members.where((m) => m.memberId == id).firstOrNull;
              onChanged(member);
            }
          },
        ),
      ),
    );
  }
}
