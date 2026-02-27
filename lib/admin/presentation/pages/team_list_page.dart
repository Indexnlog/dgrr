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
        builder: (context, snapshot) {
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
                  Icon(Icons.groups_outlined, size: 64, color: Colors.grey.shade400),
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

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  title: Text(name),
                  subtitle: Text(teamId, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.go('/admin/teams/$teamId/members'),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
