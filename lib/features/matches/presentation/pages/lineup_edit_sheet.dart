import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../teams/domain/entities/member.dart';
import '../../../teams/presentation/providers/current_team_provider.dart';
import '../../../teams/presentation/providers/team_members_provider.dart';
import '../../domain/entities/match.dart';
import '../providers/match_providers.dart';

class _C {
  _C._();
  static const bg = Color(0xFF0D1117);
  static const card = Color(0xFF161B22);
  static const red = Color(0xFFDC2626);
  static const green = Color(0xFF2EA043);
  static const text = Color(0xFFF0F6FC);
  static const sub = Color(0xFF8B949E);
  static const muted = Color(0xFF484F58);
  static const divider = Color(0xFF30363D);
}

/// 라인업 편집 바텀시트 (감독 전용)
Future<void> showLineupEditSheet(
  BuildContext context, {
  required Match match,
  required String matchId,
}) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: _C.bg,
    builder: (ctx) => DraggableScrollableSheet(
      initialChildSize: 0.7,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, scrollController) => _LineupEditSheet(
        match: match,
        matchId: matchId,
        scrollController: scrollController,
      ),
    ),
  );
}

class _LineupEditSheet extends ConsumerStatefulWidget {
  const _LineupEditSheet({
    required this.match,
    required this.matchId,
    required this.scrollController,
  });

  final Match match;
  final String matchId;
  final ScrollController scrollController;

  @override
  ConsumerState<_LineupEditSheet> createState() => _LineupEditSheetState();
}

class _LineupEditSheetState extends ConsumerState<_LineupEditSheet> {
  late List<String> _orderedUids;
  late int _lineupSize;
  String? _captainId;
  bool _announceOnMatchDay = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final source = widget.match.participants ?? widget.match.attendees ?? [];
    _orderedUids = List.from(widget.match.lineup ?? source);
    if (_orderedUids.isEmpty && source.isNotEmpty) {
      _orderedUids = List.from(source);
    }
    _lineupSize = widget.match.effectiveLineupSize;
    _captainId = widget.match.captainId;
  }

  DateTime? _matchStartDateTime() {
    final date = widget.match.date;
    final startTime = widget.match.startTime;
    if (date == null) return null;
    if (startTime == null || startTime.isEmpty) {
      return DateTime(date.year, date.month, date.day);
    }
    final parts = startTime.split(':');
    final hour = parts.isNotEmpty ? int.tryParse(parts[0]) ?? 0 : 0;
    final minute = parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0;
    return DateTime(date.year, date.month, date.day, hour, minute);
  }

  @override
  Widget build(BuildContext context) {
    final members = ref.watch(teamMembersProvider).value ?? [];
    final memberMap = {for (final m in members) m.memberId: m};

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            decoration: BoxDecoration(
              color: _C.muted,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            child: Row(
              children: [
                const Text(
                  '라인업 설정',
                  style: TextStyle(
                    color: _C.text,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close, color: _C.sub),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              controller: widget.scrollController,
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              children: [
                _buildLineupSizeSelector(),
                const SizedBox(height: 16),
                _buildAnnounceToggle(),
                const SizedBox(height: 20),
                _buildCaptainSelector(members),
                const SizedBox(height: 20),
                _buildReorderList(memberMap),
                const SizedBox(height: 24),
                _buildSaveButton(memberMap),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLineupSizeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '필드 선수 수',
          style: TextStyle(color: _C.sub, fontSize: 12, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Row(
          children: [5, 6, 7].map((n) {
            final selected = _lineupSize == n;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () => setState(() => _lineupSize = n),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: selected ? _C.green.withOpacity(0.2) : _C.muted.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: selected ? _C.green : _C.divider,
                    ),
                  ),
                  child: Text(
                    '$n명',
                    style: TextStyle(
                      color: selected ? _C.green : _C.sub,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildAnnounceToggle() {
    return Row(
      children: [
        SizedBox(
          width: 24,
          height: 24,
          child: Checkbox(
            value: _announceOnMatchDay,
            onChanged: (v) => setState(() => _announceOnMatchDay = v ?? false),
            activeColor: _C.green,
            fillColor: WidgetStateProperty.resolveWith((_) => _C.muted),
          ),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Text(
            '경기 당일 공개 (시작 시각 이후에만 표시)',
            style: TextStyle(color: _C.text, fontSize: 14),
          ),
        ),
      ],
    );
  }

  Widget _buildCaptainSelector(List<Member> members) {
    final memberMap = {for (final m in members) m.memberId: m};
    final options = _orderedUids
        .map((uid) => memberMap[uid])
        .whereType<Member>()
        .toList();
    if (options.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '주장',
          style: TextStyle(color: _C.sub, fontSize: 12, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _captainId,
          decoration: InputDecoration(
            filled: true,
            fillColor: _C.card,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          dropdownColor: _C.card,
          style: const TextStyle(color: _C.text),
          items: [
            const DropdownMenuItem(value: null, child: Text('선택 안 함', style: TextStyle(color: _C.sub))),
            ...options.map((m) => DropdownMenuItem(
                  value: m.memberId,
                  child: Text('${m.number != null ? "${m.number}번 " : ""}${m.name}'),
                )),
          ],
          onChanged: (v) => setState(() => _captainId = v),
        ),
      ],
    );
  }

  Widget _buildReorderList(Map<String, Member> memberMap) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '순서 (앞 ${_lineupSize}명 = 선발)',
          style: const TextStyle(color: _C.sub, fontSize: 12, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        ReorderableListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _orderedUids.length,
          onReorder: (oldIndex, newIndex) {
            setState(() {
              if (newIndex > oldIndex) newIndex--;
              final item = _orderedUids.removeAt(oldIndex);
              _orderedUids.insert(newIndex, item);
            });
          },
          itemBuilder: (context, index) {
            final uid = _orderedUids[index];
            final member = memberMap[uid];
            final isStarter = index < _lineupSize;
            return Container(
              key: ValueKey(uid),
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isStarter ? _C.green.withOpacity(0.1) : _C.card,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _C.divider),
              ),
              child: Row(
                children: [
                  Icon(Icons.drag_handle, color: _C.muted, size: 20),
                  const SizedBox(width: 12),
                  Text(
                    '${index + 1}',
                    style: const TextStyle(color: _C.sub, fontSize: 12, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    member?.name ?? uid,
                    style: const TextStyle(color: _C.text, fontWeight: FontWeight.w600),
                  ),
                  if (member?.number != null) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: _C.muted.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '${member!.number}번',
                        style: const TextStyle(color: _C.sub, fontSize: 11),
                      ),
                    ),
                  ],
                  if (_captainId == uid) ...[
                    const SizedBox(width: 8),
                    const Text('(주장)', style: TextStyle(color: _C.green, fontSize: 12)),
                  ],
                  const Spacer(),
                  Text(
                    isStarter ? '선발' : '벤치',
                    style: TextStyle(
                      color: isStarter ? _C.green : _C.muted,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildSaveButton(Map<String, Member> memberMap) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton(
        onPressed: _saving ? null : () => _save(memberMap),
        style: FilledButton.styleFrom(
          backgroundColor: _C.green,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: _saving
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
            : const Text('저장', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
    );
  }

  Future<void> _save(Map<String, Member> memberMap) async {
    final teamId = ref.read(currentTeamIdProvider);
    if (teamId == null) return;

    setState(() => _saving = true);

    try {
      final ds = ref.read(matchDataSourceProvider);
      DateTime? lineupAnnouncedAt;
      if (_announceOnMatchDay) {
        lineupAnnouncedAt = _matchStartDateTime();
      }

      await ds.updateLineup(
        teamId,
        widget.matchId,
        lineup: _orderedUids,
        lineupSize: _lineupSize,
        captainId: _captainId,
        lineupAnnouncedAt: lineupAnnouncedAt,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('라인업이 저장되었습니다'), backgroundColor: _C.green),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('저장 실패: $e'), backgroundColor: _C.red),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}
