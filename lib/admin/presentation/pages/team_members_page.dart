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
        builder: (context, teamSnapshot) {
          if (!teamSnapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final teamName =
              (teamSnapshot.data!.data() as Map<String, dynamic>?)?['name'] as String? ??
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
              final pending = docs.where((d) => (d.data() as Map)['status'] == 'pending').toList();
              final active = docs.where((d) => (d.data() as Map)['status'] == 'active').toList();
              final others = docs.where((d) {
                final s = (d.data() as Map)['status'] as String?;
                return s != 'pending' && s != 'active';
              }).toList();

              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Text(
                    teamName,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 24),
                  if (pending.isNotEmpty) ...[
                    Text(
                      '가입 신청 (${pending.length}명)',
                      style: TextStyle(
                        color: Colors.orange.shade800,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...pending.map((d) => _MemberCard(
                          doc: d,
                          teamId: teamId,
                          onApprove: () async {
                            await d.reference.update({'status': 'active'});
                          },
                          onReject: () async {
                            await d.reference.update({'status': 'rejected'});
                          },
                        )),
                    const SizedBox(height: 24),
                  ],
                  Text(
                    '활동 멤버 (${active.length}명)',
                    style: TextStyle(
                      color: Colors.green.shade800,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...active.map((d) => _MemberCard(doc: d, teamId: teamId)),
                  if (others.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    Text(
                      '기타 (${others.length}명)',
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
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
}

class _MemberCard extends StatelessWidget {
  const _MemberCard({
    required this.doc,
    required this.teamId,
    this.onApprove,
    this.onReject,
  });

  final QueryDocumentSnapshot doc;
  final String teamId;
  final Future<void> Function()? onApprove;
  final Future<void> Function()? onReject;

  @override
  Widget build(BuildContext context) {
    final data = doc.data() as Map<String, dynamic>;
    final memberId = doc.id;
    final name = data['name'] as String? ?? data['uniformName'] as String? ?? '(이름 없음)';
    final status = data['status'] as String? ?? 'unknown';
    final isPending = status == 'pending';

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              child: Text(name.isNotEmpty ? name.substring(0, 1) : '?'),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
                  Text(
                    memberId,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                  if (isPending)
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade100,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '승인 대기',
                        style: TextStyle(fontSize: 12, color: Colors.orange.shade800),
                      ),
                    ),
                ],
              ),
            ),
            if (isPending && onApprove != null && onReject != null)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextButton(
                    onPressed: onApprove != null ? () => onApprove!() : null,
                    child: const Text('승인'),
                  ),
                  TextButton(
                    onPressed: onReject != null ? () => onReject!() : null,
                    style: TextButton.styleFrom(foregroundColor: Colors.red),
                    child: const Text('거절'),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
