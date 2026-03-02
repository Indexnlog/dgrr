import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// 팀 멤버 목록 + 가입 신청 승인/거절 (어드민)
class TeamMembersPage extends ConsumerWidget {
  const TeamMembersPage({super.key, required this.teamId});

  final String teamId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('멤버 관리'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/admin/teams'),
        ),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('teams')
            .doc(teamId)
            .snapshots(),
        builder: (_, teamSnapshot) {
          if (!teamSnapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final teamName =
              (teamSnapshot.data!.data() as Map<String, dynamic>?)?['name']
                      as String? ??
                  teamId;

          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('teams')
                .doc(teamId)
                .collection('members')
                .orderBy('joinedAt', descending: true)
                .snapshots(),
            builder: (context, memberSnapshot) {
              if (!memberSnapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final docs = memberSnapshot.data!.docs;
              final pending = docs
                  .where((d) => (d.data() as Map)['status'] == 'pending')
                  .toList();
              final active = docs
                  .where((d) => (d.data() as Map)['status'] == 'active')
                  .toList();
              final others = docs.where((d) {
                final s = (d.data() as Map)['status'] as String?;
                return s != 'pending' && s != 'active';
              }).toList();

              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // 팀 이름 + 수정 버튼
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          teamName,
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () =>
                            context.go('/admin/teams/$teamId/edit'),
                        icon: const Icon(Icons.edit_outlined, size: 16),
                        label: const Text('팀 정보 수정'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '전체 ${docs.length}명 (대기 ${pending.length} / 활동 ${active.length})',
                    style:
                        TextStyle(fontSize: 13, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 24),

                  // 가입 신청 섹션
                  if (pending.isNotEmpty) ...[
                    _SectionHeader(
                      label: '가입 신청',
                      count: pending.length,
                      color: Colors.orange.shade800,
                      trailing: TextButton(
                        onPressed: () =>
                            _approveAll(context, pending),
                        child: const Text('전체 승인'),
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...pending.map((d) => _MemberCard(
                          doc: d,
                          teamId: teamId,
                          onApprove: () async {
                            await _updateStatus(
                                context, d, teamId, 'active');
                          },
                          onReject: () async {
                            await _updateStatus(
                                context, d, teamId, 'rejected');
                          },
                        )),
                    const SizedBox(height: 24),
                  ],

                  // 활동 멤버 섹션
                  _SectionHeader(
                    label: '활동 멤버',
                    count: active.length,
                    color: Colors.green.shade800,
                  ),
                  const SizedBox(height: 8),
                  if (active.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        '활동 멤버가 없습니다.',
                        style: TextStyle(color: Colors.grey.shade500),
                      ),
                    )
                  else
                    ...active.map((d) => _MemberCard(
                          doc: d,
                          teamId: teamId,
                          onKick: () => _confirmKick(context, d, teamId),
                        )),

                  // 기타(거절 등) 섹션
                  if (others.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    _SectionHeader(
                      label: '기타',
                      count: others.length,
                      color: Colors.grey.shade700,
                    ),
                    const SizedBox(height: 8),
                    ...others.map((d) => _MemberCard(doc: d, teamId: teamId)),
                  ],
                ],
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _updateStatus(
    BuildContext context,
    QueryDocumentSnapshot doc,
    String teamId,
    String newStatus,
  ) async {
    try {
      final fs = FirebaseFirestore.instance;
      await doc.reference.update({'status': newStatus});

      // memberCount 업데이트
      if (newStatus == 'active') {
        await fs.collection('teams_public').doc(teamId).update({
          'memberCount': FieldValue.increment(1),
        });
      } else if ((doc.data() as Map)['status'] == 'active') {
        await fs.collection('teams_public').doc(teamId).update({
          'memberCount': FieldValue.increment(-1),
        });
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('처리 실패: $e')),
        );
      }
    }
  }

  Future<void> _approveAll(
      BuildContext context, List<QueryDocumentSnapshot> pending) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('전체 승인'),
        content: Text('대기 중인 ${pending.length}명을 모두 승인하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('승인'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    try {
      final fs = FirebaseFirestore.instance;
      final batch = fs.batch();
      for (final d in pending) {
        batch.update(d.reference, {'status': 'active'});
      }
      await batch.commit();
      await fs.collection('teams_public').doc(teamId).update({
        'memberCount': FieldValue.increment(pending.length),
      });
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${pending.length}명이 승인됐습니다.')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('처리 실패: $e')),
        );
      }
    }
  }

  Future<void> _confirmKick(
    BuildContext context,
    QueryDocumentSnapshot doc,
    String teamId,
  ) async {
    final data = doc.data() as Map<String, dynamic>;
    final name = data['name'] as String? ??
        data['uniformName'] as String? ??
        '(이름 없음)';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('멤버 강퇴'),
        content: Text('"$name"을(를) 팀에서 강퇴하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('강퇴'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    await _updateStatus(context, doc, teamId, 'kicked');
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.label,
    required this.count,
    required this.color,
    this.trailing,
  });

  final String label;
  final int count;
  final Color color;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          '$label ($count명)',
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
        ),
        const Spacer(),
        if (trailing != null) trailing!,
      ],
    );
  }
}

class _MemberCard extends StatelessWidget {
  const _MemberCard({
    required this.doc,
    required this.teamId,
    this.onApprove,
    this.onReject,
    this.onKick,
  });

  final QueryDocumentSnapshot doc;
  final String teamId;
  final VoidCallback? onApprove;
  final VoidCallback? onReject;
  final VoidCallback? onKick;

  @override
  Widget build(BuildContext context) {
    final data = doc.data() as Map<String, dynamic>;
    final name = data['name'] as String? ??
        data['uniformName'] as String? ??
        '(이름 없음)';
    final status = data['status'] as String? ?? 'unknown';
    final email = data['email'] as String?;
    final joinedAt = data['joinedAt'] as Timestamp?;
    final isPending = status == 'pending';
    final isActive = status == 'active';

    String statusLabel;
    Color statusColor;
    switch (status) {
      case 'pending':
        statusLabel = '승인 대기';
        statusColor = Colors.orange.shade700;
      case 'active':
        statusLabel = '활동중';
        statusColor = Colors.green.shade700;
      case 'rejected':
        statusLabel = '거절됨';
        statusColor = Colors.red.shade700;
      case 'kicked':
        statusLabel = '강퇴됨';
        statusColor = Colors.red.shade900;
      default:
        statusLabel = status;
        statusColor = Colors.grey.shade700;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: isPending
                  ? Colors.orange.shade100
                  : isActive
                      ? Colors.blue.shade100
                      : Colors.grey.shade100,
              child: Text(
                name.isNotEmpty ? name.substring(0, 1) : '?',
                style: TextStyle(
                  color: isPending
                      ? Colors.orange.shade700
                      : isActive
                          ? Colors.blue.shade700
                          : Colors.grey.shade700,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(name,
                          style: const TextStyle(
                              fontWeight: FontWeight.w600)),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          statusLabel,
                          style: TextStyle(
                              fontSize: 11, color: statusColor),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  if (email != null)
                    Text(email,
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey.shade600)),
                  if (joinedAt != null)
                    Text(
                      '신청일: ${_formatDate(joinedAt.toDate())}',
                      style: TextStyle(
                          fontSize: 11, color: Colors.grey.shade500),
                    ),
                ],
              ),
            ),
            // 액션 버튼
            if (isPending && onApprove != null && onReject != null)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.check_circle_outline,
                        color: Colors.green),
                    tooltip: '승인',
                    onPressed: onApprove,
                  ),
                  IconButton(
                    icon: Icon(Icons.cancel_outlined,
                        color: Colors.red.shade400),
                    tooltip: '거절',
                    onPressed: onReject,
                  ),
                ],
              )
            else if (isActive && onKick != null)
              IconButton(
                icon: Icon(Icons.person_remove_outlined,
                    color: Colors.red.shade400),
                tooltip: '강퇴',
                onPressed: onKick,
              ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.year}.${dt.month.toString().padLeft(2, '0')}.${dt.day.toString().padLeft(2, '0')}';
  }
}
