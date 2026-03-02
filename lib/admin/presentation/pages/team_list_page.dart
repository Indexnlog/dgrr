import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// 팀 목록 (어드민)
class TeamListPage extends ConsumerWidget {
  const TeamListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('팀 목록'),
        actions: [
          TextButton.icon(
            onPressed: () => context.go('/admin/teams/create'),
            icon: const Icon(Icons.add),
            label: const Text('팀 생성'),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('teams').snapshots(),
        builder: (_, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('오류: ${snapshot.error}'));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs
            ..sort((a, b) {
              final aName = (a.data() as Map)['name'] as String? ?? '';
              final bName = (b.data() as Map)['name'] as String? ?? '';
              return aName.compareTo(bName);
            });

          if (docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.groups_outlined,
                      size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text(
                    '등록된 팀이 없습니다',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: () => context.go('/admin/teams/create'),
                    icon: const Icon(Icons.add),
                    label: const Text('첫 팀 생성하기'),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, i) {
              final doc = docs[i];
              final data = doc.data() as Map<String, dynamic>;
              final name = data['name'] as String? ?? '(이름 없음)';
              final teamId = doc.id;

              return _TeamCard(
                teamId: teamId,
                name: name,
                onMembers: () => context.go('/admin/teams/$teamId/members'),
                onEdit: () => context.go('/admin/teams/$teamId/edit'),
                onDelete: () => _confirmDelete(context, teamId, name),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _confirmDelete(
      BuildContext context, String teamId, String name) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('팀 삭제'),
        content: Text(
          '"$name" 팀을 삭제하시겠습니까?\n\n멤버 데이터도 함께 삭제됩니다. 이 작업은 되돌릴 수 없습니다.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('삭제'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    try {
      final fs = FirebaseFirestore.instance;
      final members = await fs
          .collection('teams')
          .doc(teamId)
          .collection('members')
          .get();
      final batch = fs.batch();
      for (final m in members.docs) {
        batch.delete(m.reference);
      }
      batch.delete(fs.collection('teams').doc(teamId));
      batch.delete(fs.collection('teams_public').doc(teamId));
      await batch.commit();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('"$name" 팀이 삭제됐습니다.')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('삭제 실패: $e')),
        );
      }
    }
  }
}

class _TeamCard extends StatelessWidget {
  const _TeamCard({
    required this.teamId,
    required this.name,
    required this.onMembers,
    required this.onEdit,
    required this.onDelete,
  });

  final String teamId;
  final String name;
  final VoidCallback onMembers;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('teams_public')
            .doc(teamId)
            .snapshots(),
        builder: (_, snap) {
          final pub = snap.hasData && snap.data!.exists
              ? snap.data!.data() as Map<String, dynamic>
              : <String, dynamic>{};
          final region = pub['region'] as String? ?? '';
          final memberCount = pub['memberCount'] as int? ?? 0;
          final isOpen = pub['isOpenJoin'] as bool? ?? true;

          return ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    name,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: isOpen
                        ? Colors.green.shade50
                        : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isOpen
                          ? Colors.green.shade300
                          : Colors.grey.shade300,
                    ),
                  ),
                  child: Text(
                    isOpen ? '모집중' : '모집종료',
                    style: TextStyle(
                      fontSize: 11,
                      color: isOpen
                          ? Colors.green.shade700
                          : Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Row(
                children: [
                  if (region.isNotEmpty && region != '미정') ...[
                    Icon(Icons.location_on_outlined,
                        size: 13, color: Colors.grey.shade500),
                    const SizedBox(width: 2),
                    Text(region,
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey.shade600)),
                    const SizedBox(width: 12),
                  ],
                  Icon(Icons.people_outline,
                      size: 13, color: Colors.grey.shade500),
                  const SizedBox(width: 2),
                  Text('$memberCount명',
                      style: TextStyle(
                          fontSize: 12, color: Colors.grey.shade600)),
                  const SizedBox(width: 12),
                  Flexible(
                    child: Text(teamId,
                        style: TextStyle(
                            fontSize: 11, color: Colors.grey.shade400),
                        overflow: TextOverflow.ellipsis),
                  ),
                ],
              ),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 20),
                  tooltip: '팀 정보 수정',
                  onPressed: onEdit,
                ),
                IconButton(
                  icon: Icon(Icons.delete_outline,
                      size: 20, color: Colors.red.shade400),
                  tooltip: '팀 삭제',
                  onPressed: onDelete,
                ),
                IconButton(
                  icon: const Icon(Icons.people, size: 20),
                  tooltip: '멤버 관리',
                  onPressed: onMembers,
                ),
              ],
            ),
            onTap: onMembers,
          );
        },
      ),
    );
  }
}
