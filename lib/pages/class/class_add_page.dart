import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ClassAddPage extends StatefulWidget {
  const ClassAddPage({super.key});

  @override
  State<ClassAddPage> createState() => _ClassAddPageState();
}

class _ClassAddPageState extends State<ClassAddPage> {
  final _titleController = TextEditingController();
  final _locationController = TextEditingController();
  final _startTimeController = TextEditingController();
  final _endTimeController = TextEditingController();

  DateTime? _selectedDate;
  DateTime? _registerStart;
  DateTime? _registerEnd;

  /// 📌 수업 날짜 선택
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

  /// 📌 등록기간 날짜 선택
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

  /// 📌 Firestore에 수업 저장
  Future<void> _saveClass() async {
    if (_titleController.text.isEmpty ||
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

    await FirebaseFirestore.instance.collection('classes').add({
      'title': _titleController.text.trim(),
      'location': _locationController.text.trim(),
      'startTime': _startTimeController.text.trim(),
      'endTime': _endTimeController.text.trim(),
      'date': Timestamp.fromDate(_selectedDate!), // ✅ 수업 날짜
      'registerStart': Timestamp.fromDate(_registerStart!), // ✅ 등록 시작
      'registerEnd': Timestamp.fromDate(_registerEnd!), // ✅ 등록 종료
      'status': 'active',
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
  void dispose() {
    _titleController.dispose();
    _locationController.dispose();
    _startTimeController.dispose();
    _endTimeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('➕ 수업 등록')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: '수업명',
                prefixIcon: Icon(Icons.school),
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

            // 📅 수업 날짜
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

            // 📅 등록 시작
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

            // 📅 등록 종료
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
