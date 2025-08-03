import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../providers/user_role_provider.dart';

class MatchAddPage extends StatefulWidget {
  final String teamId;

  const MatchAddPage({super.key, required this.teamId});

  @override
  State<MatchAddPage> createState() => _MatchAddPageState();
}

class _MatchAddPageState extends State<MatchAddPage> {
  late final TextEditingController _teamNameController;
  late final TextEditingController _locationController;
  late final TextEditingController _startTimeController;
  late final TextEditingController _endTimeController;

  DateTime? _selectedDate;
  DateTime? _registerStart;
  DateTime? _registerEnd;

  @override
  void initState() {
    super.initState();
    _teamNameController = TextEditingController();
    _locationController = TextEditingController();
    _startTimeController = TextEditingController();
    _endTimeController = TextEditingController();
  }

  @override
  void dispose() {
    _teamNameController.dispose();
    _locationController.dispose();
    _startTimeController.dispose();
    _endTimeController.dispose();
    super.dispose();
  }

  Future<void> _pickDate(
    BuildContext context,
    void Function(DateTime) onPicked,
  ) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() => onPicked(picked));
    }
  }

  Future<void> _saveMatch() async {
    if (_teamNameController.text.isEmpty ||
        _locationController.text.isEmpty ||
        _startTimeController.text.isEmpty ||
        _endTimeController.text.isEmpty ||
        _selectedDate == null ||
        _registerStart == null ||
        _registerEnd == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('모든 필드를 입력해주세요')));
      return;
    }

    await FirebaseFirestore.instance
        .collection('teams')
        .doc(widget.teamId)
        .collection('matches')
        .add({
          'teamName': _teamNameController.text.trim(),
          'location': _locationController.text.trim(),
          'startTime': _startTimeController.text.trim(),
          'endTime': _endTimeController.text.trim(),
          'date': Timestamp.fromDate(_selectedDate!),
          'registerStart': Timestamp.fromDate(_registerStart!),
          'registerEnd': Timestamp.fromDate(_registerEnd!),
          'recruitStatus': 'confirmed',
          'createdAt': FieldValue.serverTimestamp(),
          'teamId': widget.teamId,
        });

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('✅ 매치가 등록되었습니다.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final role = context.watch<UserRoleProvider>().role;
    final isMatchManager = role == '경기팀';

    if (!isMatchManager) {
      return const Scaffold(
        body: Center(child: Text('⚠️ 경기팀만 매치를 등록할 수 있습니다')),
      );
    }

    final dateFormat = DateFormat('yyyy-MM-dd');

    return Scaffold(
      appBar: AppBar(title: const Text('➕ 매치 등록')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _teamNameController,
              decoration: const InputDecoration(
                labelText: '상대팀 이름',
                prefixIcon: Icon(Icons.sports_soccer),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _locationController,
              decoration: const InputDecoration(
                labelText: '장소',
                prefixIcon: Icon(Icons.place),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _startTimeController,
              decoration: const InputDecoration(
                labelText: '시작 시간 (예: 18:00)',
                prefixIcon: Icon(Icons.schedule),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _endTimeController,
              decoration: const InputDecoration(
                labelText: '종료 시간 (예: 20:00)',
                prefixIcon: Icon(Icons.schedule),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Text(
                    _selectedDate == null
                        ? '📅 매치 날짜 선택 안됨'
                        : '매치 날짜: ${dateFormat.format(_selectedDate!)}',
                  ),
                ),
                TextButton(
                  onPressed: () =>
                      _pickDate(context, (picked) => _selectedDate = picked),
                  child: const Text('매치 날짜 선택'),
                ),
              ],
            ),
            Row(
              children: [
                Expanded(
                  child: Text(
                    _registerStart == null
                        ? '📅 등록 시작일 선택 안됨'
                        : '등록 시작: ${dateFormat.format(_registerStart!)}',
                  ),
                ),
                TextButton(
                  onPressed: () =>
                      _pickDate(context, (picked) => _registerStart = picked),
                  child: const Text('등록 시작일'),
                ),
              ],
            ),
            Row(
              children: [
                Expanded(
                  child: Text(
                    _registerEnd == null
                        ? '📅 등록 종료일 선택 안됨'
                        : '등록 종료: ${dateFormat.format(_registerEnd!)}',
                  ),
                ),
                TextButton(
                  onPressed: () =>
                      _pickDate(context, (picked) => _registerEnd = picked),
                  child: const Text('등록 종료일'),
                ),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.save),
                label: const Text('✅ 저장'),
                onPressed: _saveMatch,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
