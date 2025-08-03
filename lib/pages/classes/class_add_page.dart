import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';

import '../../providers/user_role_provider.dart'; // ✅ 추가

class ClassAddPage extends StatefulWidget {
  const ClassAddPage({super.key});

  @override
  State<ClassAddPage> createState() => _ClassAddPageState();
}

class _ClassAddPageState extends State<ClassAddPage> {
  final _locationController = TextEditingController();
  final _startTimeController = TextEditingController();
  final _endTimeController = TextEditingController();

  DateTime? _selectedDate;
  DateTime? _registerStart;
  DateTime? _registerEnd;

  @override
  void dispose() {
    _locationController.dispose();
    _startTimeController.dispose();
    _endTimeController.dispose();
    super.dispose();
  }

  Future<void> _pickClassDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _pickDate(BuildContext context, bool isRegisterStart) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        if (isRegisterStart) {
          _registerStart = picked;
        } else {
          _registerEnd = picked;
        }
      });
    }
  }

  Future<void> _saveClass() async {
    if (_locationController.text.isEmpty ||
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

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    // ✅ 로그인한 사용자의 teamId 찾기
    final teamsSnapshot = await FirebaseFirestore.instance
        .collection('teams')
        .get();

    String? teamId;
    for (var doc in teamsSnapshot.docs) {
      final memberDoc = await doc.reference
          .collection('members')
          .doc(uid)
          .get();
      if (memberDoc.exists) {
        teamId = doc.id;
        break;
      }
    }

    if (teamId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('팀 정보를 찾을 수 없습니다')));
      return;
    }

    await FirebaseFirestore.instance
        .collection('teams')
        .doc(teamId)
        .collection('classes')
        .add({
          'teamId': teamId,
          'date': _selectedDate!.toIso8601String().split('T').first,
          'startTime': _startTimeController.text.trim(),
          'endTime': _endTimeController.text.trim(),
          'location': _locationController.text.trim(),
          'registerStart': Timestamp.fromDate(_registerStart!),
          'registerEnd': Timestamp.fromDate(_registerEnd!),
          'status': 'active',
          'type': 'lesson',
          'attendance': {'absent': 0, 'present': 0, 'attendees': []},
          'comments': [],
          'createdAt': FieldValue.serverTimestamp(),
        });

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('✅ 수업이 등록되었습니다.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final role = context.watch<UserRoleProvider>().role;
    final isLessonManager = role == '수업팀';

    if (!isLessonManager) {
      return const Scaffold(
        body: Center(child: Text('⚠️ 수업팀만 수업을 등록할 수 있습니다')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('➕ 수업 등록')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
                prefixIcon: Icon(Icons.access_time),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _endTimeController,
              decoration: const InputDecoration(
                labelText: '종료 시간 (예: 20:00)',
                prefixIcon: Icon(Icons.access_time),
              ),
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: Text(
                    _selectedDate == null
                        ? '📅 수업 날짜 선택 안됨'
                        : '수업 날짜: ${_selectedDate!.toLocal()}',
                  ),
                ),
                TextButton(
                  onPressed: () => _pickClassDate(context),
                  child: const Text('수업 날짜 선택'),
                ),
              ],
            ),
            Row(
              children: [
                Expanded(
                  child: Text(
                    _registerStart == null
                        ? '📅 등록 시작일 선택 안됨'
                        : '등록 시작: ${_registerStart!.toLocal()}',
                  ),
                ),
                TextButton(
                  onPressed: () => _pickDate(context, true),
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
                        : '등록 종료: ${_registerEnd!.toLocal()}',
                  ),
                ),
                TextButton(
                  onPressed: () => _pickDate(context, false),
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
                onPressed: _saveClass,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
