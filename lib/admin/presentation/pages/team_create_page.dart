import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// 팀 생성 (어드민)
class TeamCreatePage extends ConsumerStatefulWidget {
  const TeamCreatePage({super.key});

  @override
  ConsumerState<TeamCreatePage> createState() => _TeamCreatePageState();
}

class _TeamCreatePageState extends ConsumerState<TeamCreatePage> {
  final _formKey = GlobalKey<FormState>();
  final _teamIdController = TextEditingController();
  final _nameController = TextEditingController();
  final _regionController = TextEditingController();
  final _introController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _teamIdController.dispose();
    _nameController.dispose();
    _regionController.dispose();
    _introController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final teamId = _teamIdController.text.trim();
      final name = _nameController.text.trim();
      final region = _regionController.text.trim();
      final intro = _introController.text.trim();

      final firestore = FirebaseFirestore.instance;

      // teams (코어)
      await firestore.collection('teams').doc(teamId).set({
        'teamId': teamId,
        'name': name,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // teams_public (검색용)
      await firestore.collection('teams_public').doc(teamId).set({
        'teamId': teamId,
        'name': name,
        'region': region.isNotEmpty ? region : '미정',
        'intro': intro.isNotEmpty ? intro : '팀 소개를 입력해주세요.',
        'isOpenJoin': true,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$name 팀이 생성되었습니다.')),
        );
        context.go('/admin/teams');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('생성 실패: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('팀 생성'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/admin/teams'),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _teamIdController,
                decoration: const InputDecoration(
                  labelText: '팀 ID (영문, 숫자, _)',
                  hintText: '예: youngwon_fc',
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return '팀 ID를 입력하세요';
                  if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(v.trim())) {
                    return '영문, 숫자, _ 만 사용 가능';
                  }
                  return null;
                },
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: '팀명',
                  hintText: '예: 영원FC',
                ),
                validator: (v) => (v == null || v.isEmpty) ? '팀명을 입력하세요' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _regionController,
                decoration: const InputDecoration(
                  labelText: '지역',
                  hintText: '예: 서울 금천구',
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _introController,
                decoration: const InputDecoration(
                  labelText: '팀 소개',
                  hintText: '팀을 소개해주세요.',
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 32),
              FilledButton(
                onPressed: _isSubmitting ? null : _submit,
                child: _isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('팀 생성'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
