import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/errors.dart';

import '../../../teams/presentation/providers/current_team_provider.dart';
import '../../data/models/opponent_model.dart';
import '../providers/opponent_providers.dart';

class _C {
  _C._();
  static const bg = Color(0xFF0D1117);
  static const card = Color(0xFF161B22);
  static const green = Color(0xFF2EA043);
  static const red = Color(0xFFDC2626);
  static const text = Color(0xFFF0F6FC);
  static const sub = Color(0xFF8B949E);
  static const muted = Color(0xFF484F58);
  static const divider = Color(0xFF30363D);
}

/// 상대팀 목록 및 관리 페이지
class OpponentListPage extends ConsumerStatefulWidget {
  const OpponentListPage({super.key});

  @override
  ConsumerState<OpponentListPage> createState() => _OpponentListPageState();
}

class _OpponentListPageState extends ConsumerState<OpponentListPage> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final opponentsAsync = ref.watch(opponentsProvider);

    return Scaffold(
      backgroundColor: _C.bg,
      appBar: AppBar(
        backgroundColor: _C.card,
        foregroundColor: _C.text,
        title: const Text('상대팀 관리'),
        elevation: 0,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            child: TextField(
              controller: _searchController,
              onChanged: (v) => setState(() => _searchQuery = v.trim().toLowerCase()),
              style: const TextStyle(color: _C.text),
              decoration: InputDecoration(
                hintText: '상대팀명으로 검색',
                hintStyle: const TextStyle(color: _C.muted),
                prefixIcon: const Icon(Icons.search, color: _C.muted, size: 20),
                filled: true,
                fillColor: _C.card,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                isDense: true,
              ),
            ),
          ),
          Expanded(
            child: opponentsAsync.when(
              data: (opponents) {
                final filtered = _searchQuery.isEmpty
                    ? opponents
                    : opponents.where((o) =>
                        (o.name ?? '').toLowerCase().contains(_searchQuery) ||
                        (o.contact ?? '').toLowerCase().contains(_searchQuery)).toList();
                if (filtered.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.groups_outlined, size: 56, color: _C.muted.withValues(alpha: 0.5)),
                  const SizedBox(height: 16),
                  Text(
                    _searchQuery.isEmpty ? '등록된 상대팀이 없습니다' : '검색 결과가 없습니다',
                    style: TextStyle(color: _C.muted, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '경기 생성 시 상대팀을 입력하면 자동 등록됩니다',
                    style: TextStyle(color: _C.muted.withValues(alpha: 0.8), fontSize: 12),
                  ),
                ],
              ),
            );
          }
                return ListView.separated(
                  padding: const EdgeInsets.all(20),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final o = filtered[index];
              return _OpponentTile(
                opponent: o,
                onEdit: () => _OpponentListPageState._showOpponentEditSheet(context, ref, o),
                onDelete: () => _OpponentListPageState._confirmDeleteOpponent(context, ref, o),
                    );
                  },
                );
              },
              loading: () => const Center(
                child: CircularProgressIndicator(color: _C.green, strokeWidth: 2),
              ),
              error: (e, _) => Center(
                child: Text('오류: $e', style: const TextStyle(color: _C.sub)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static Future<void> _showOpponentEditSheet(BuildContext context, WidgetRef ref, OpponentModel o) async {
    final teamId = ref.read(currentTeamIdProvider);
    if (teamId == null) return;

    final nameController = TextEditingController(text: o.name ?? '');
    final contactController = TextEditingController(text: o.contact ?? '');
    var status = o.status ?? 'seeking';

    final result = await showModalBottomSheet<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => Container(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('상대팀 수정', style: TextStyle(color: _C.text, fontSize: 18, fontWeight: FontWeight.w700)),
                const SizedBox(height: 16),
                TextField(
                  controller: nameController,
                  style: const TextStyle(color: _C.text),
                  decoration: InputDecoration(
                    labelText: '상대팀명',
                    filled: true,
                    fillColor: _C.card,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: contactController,
                  style: const TextStyle(color: _C.text),
                  decoration: InputDecoration(
                    labelText: '연락처',
                    filled: true,
                    fillColor: _C.card,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _StatusChip(label: '모집 중', value: 'seeking', selected: status == 'seeking', onTap: () => setState(() => status = 'seeking')),
                    const SizedBox(width: 8),
                    _StatusChip(label: '확정', value: 'confirmed', selected: status == 'confirmed', onTap: () => setState(() => status = 'confirmed')),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(child: OutlinedButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('취소', style: TextStyle(color: _C.muted)))),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: () {
                          if (nameController.text.trim().isEmpty) return;
                          Navigator.pop(ctx, true);
                        },
                        style: FilledButton.styleFrom(backgroundColor: _C.green),
                        child: const Text('저장'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (result == true && nameController.text.trim().isNotEmpty) {
      try {
        await ref.read(opponentDataSourceProvider).updateOpponent(
          teamId,
          o.opponentId,
          name: nameController.text.trim(),
          contact: contactController.text.trim().isEmpty ? null : contactController.text.trim(),
          status: status,
        );
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('상대팀이 수정되었습니다'), backgroundColor: _C.green),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ErrorHandler.showError(context, e, fallback: '수정에 실패했습니다');
        }
      }
    }
  }

  static Future<void> _confirmDeleteOpponent(BuildContext context, WidgetRef ref, OpponentModel o) async {
    final teamId = ref.read(currentTeamIdProvider);
    if (teamId == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _C.card,
        title: const Text('상대팀 삭제', style: TextStyle(color: _C.text)),
        content: Text(
          '${o.name ?? "이 상대팀"}을(를) 삭제하시겠습니까?\n연결된 경기 기록은 유지됩니다.',
          style: const TextStyle(color: _C.sub),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('취소', style: TextStyle(color: _C.muted))),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('삭제', style: TextStyle(color: _C.red))),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await ref.read(opponentDataSourceProvider).deleteOpponent(teamId, o.opponentId);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('상대팀이 삭제되었습니다'), backgroundColor: _C.green),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ErrorHandler.showError(context, e, fallback: '삭제에 실패했습니다');
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
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? _C.green.withValues(alpha: 0.15) : _C.muted.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: selected ? _C.green : _C.divider),
        ),
        child: Text(label, style: TextStyle(color: selected ? _C.green : _C.sub, fontWeight: FontWeight.w600, fontSize: 13)),
      ),
    );
  }
}

class _OpponentTile extends StatelessWidget {
  const _OpponentTile({
    required this.opponent,
    required this.onEdit,
    required this.onDelete,
  });
  final OpponentModel opponent;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final rec = opponent.records;
    final total = rec?.total ?? 0;
    final recent = opponent.recentResults ?? [];

    return InkWell(
      onTap: onEdit,
      borderRadius: BorderRadius.circular(12),
      child: Container(
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
                Expanded(
                  child: Text(
                    opponent.name ?? '이름 없음',
                    style: const TextStyle(color: _C.text, fontSize: 17, fontWeight: FontWeight.w700),
                  ),
                ),
                if (opponent.status == 'confirmed')
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _C.green.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text('확정', style: TextStyle(color: _C.green, fontSize: 10, fontWeight: FontWeight.w700)),
                ),
                PopupMenuButton<String>(
                  icon: Icon(Icons.more_vert, color: _C.sub, size: 20),
                  color: _C.card,
                  onSelected: (v) {
                    if (v == 'edit') onEdit();
                    if (v == 'delete') onDelete();
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(value: 'edit', child: Text('수정', style: TextStyle(color: _C.text))),
                    const PopupMenuItem(value: 'delete', child: Text('삭제', style: TextStyle(color: _C.red))),
                  ],
                ),
              ],
            ),
          if (opponent.contact != null && opponent.contact!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              opponent.contact!,
              style: const TextStyle(color: _C.sub, fontSize: 12),
            ),
          ],
          if (total > 0) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                _RecordChip(label: '승', count: rec?.wins ?? 0, color: _C.green),
                const SizedBox(width: 8),
                _RecordChip(label: '무', count: rec?.draws ?? 0, color: _C.muted),
                const SizedBox(width: 8),
                _RecordChip(label: '패', count: rec?.losses ?? 0, color: _C.red),
                if (recent.isNotEmpty) ...[
                  const Spacer(),
                  Text(
                    recent.take(5).join(' '),
                    style: TextStyle(color: _C.sub, fontSize: 11, fontFamily: 'monospace'),
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
    ),
    );
  }
}

class _RecordChip extends StatelessWidget {
  const _RecordChip({required this.label, required this.count, required this.color});
  final String label;
  final int count;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text('$label $count', style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
    );
  }
}
