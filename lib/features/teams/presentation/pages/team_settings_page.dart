import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/permissions/permission_checker.dart';
import '../../../../core/theme/app_theme.dart';
import '../providers/current_team_provider.dart';

/// 팀 설정 (팀명 등) - 운영진만 수정 가능
class TeamSettingsPage extends ConsumerStatefulWidget {
  const TeamSettingsPage({super.key});

  @override
  ConsumerState<TeamSettingsPage> createState() => _TeamSettingsPageState();
}

class _TeamSettingsPageState extends ConsumerState<TeamSettingsPage> {
  final _nameController = TextEditingController();
  bool _isSaving = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final teamId = ref.watch(currentTeamIdProvider);
    final canEdit = PermissionChecker.isAdmin(ref) || PermissionChecker.isCoach(ref);

    if (teamId == null) {
      return const Scaffold(
        body: Center(child: Text('팀을 선택해 주세요')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('팀 설정'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        future: FirebaseFirestore.instance
            .collection('teams')
            .doc(teamId)
            .get(),
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final data = snap.data!.data();
          final name = data?['name'] as String? ?? '';
          if (_nameController.text.isEmpty && name.isNotEmpty) {
            _nameController.text = name;
          }

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text(
                '팀명',
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _nameController,
                enabled: canEdit,
                decoration: InputDecoration(
                  hintText: '팀명 입력',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                ),
              ),
              if (canEdit) ...[
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _isSaving
                        ? null
                        : () async {
                            setState(() => _isSaving = true);
                            try {
                              await FirebaseFirestore.instance
                                  .collection('teams')
                                  .doc(teamId)
                                  .update({'name': _nameController.text.trim()});
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('저장되었습니다')),
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
                          },
                    child: _isSaving
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('저장'),
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}
