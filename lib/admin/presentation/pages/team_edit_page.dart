import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// 팀 정보 수정 (어드민)
class TeamEditPage extends ConsumerStatefulWidget {
  const TeamEditPage({super.key, required this.teamId});

  final String teamId;

  @override
  ConsumerState<TeamEditPage> createState() => _TeamEditPageState();
}

class _TeamEditPageState extends ConsumerState<TeamEditPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _regionController = TextEditingController();
  final _introController = TextEditingController();
  bool _isOpenJoin = true;
  bool _isLoading = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection('teams_public')
          .doc(widget.teamId)
          .get();
      if (snap.exists && mounted) {
        final d = snap.data()!;
        _nameController.text = d['name'] as String? ?? '';
        _regionController.text = d['region'] as String? ?? '';
        _introController.text = d['intro'] as String? ?? '';
        _isOpenJoin = d['isOpenJoin'] as bool? ?? true;
      }
    } catch (_) {}
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _regionController.dispose();
    _introController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);

    try {
      final name = _nameController.text.trim();
      final region = _regionController.text.trim();
      final intro = _introController.text.trim();
      final fs = FirebaseFirestore.instance;

      await Future.wait([
        fs.collection('teams').doc(widget.teamId).update({'name': name}),
        fs.collection('teams_public').doc(widget.teamId).update({
          'name': name,
          'region': region.isEmpty ? '미정' : region,
          'intro': intro.isEmpty ? '팀 소개를 입력해주세요.' : intro,
          'isOpenJoin': _isOpenJoin,
        }),
      ]);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('팀 정보가 수정됐습니다.')),
        );
        context.go('/admin/teams');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('수정 실패: $e')),
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
        title: const Text('팀 정보 수정'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/admin/teams'),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      '팀 ID: ${widget.teamId}',
                      style: TextStyle(
                          fontSize: 13, color: Colors.grey.shade500),
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(labelText: '팀명'),
                      validator: (v) =>
                          (v == null || v.isEmpty) ? '팀명을 입력하세요' : null,
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
                      decoration:
                          const InputDecoration(labelText: '팀 소개'),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('가입 신청 받기'),
                      subtitle: Text(
                        _isOpenJoin ? '현재 모집중 (앱에서 가입 신청 가능)' : '현재 모집 종료',
                        style:
                            TextStyle(fontSize: 12, color: Colors.grey.shade600),
                      ),
                      value: _isOpenJoin,
                      onChanged: (v) => setState(() => _isOpenJoin = v),
                    ),
                    const SizedBox(height: 32),
                    FilledButton(
                      onPressed: _isSubmitting ? null : _submit,
                      child: _isSubmitting
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child:
                                  CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('저장'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
