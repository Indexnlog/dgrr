import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MatchAddPage extends StatefulWidget {
  const MatchAddPage({super.key});

  @override
  State<MatchAddPage> createState() => _MatchAddPageState();
}

class _MatchAddPageState extends State<MatchAddPage> {
  final _teamNameController = TextEditingController();
  final _locationController = TextEditingController();
  final _startTimeController = TextEditingController();
  final _endTimeController = TextEditingController();

  DateTime? _selectedDate;
  DateTime? _registerStart;
  DateTime? _registerEnd;

  /// 📌 날짜 선택 다이얼로그 (등록 시작/종료)
  Future<void> _pickDate(BuildContext context, bool isRegisterStart) async {
    final initial = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
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

  /// 📌 매치 날짜 선택
  Future<void> _pickMatchDate(BuildContext context) async {
    final initial = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  /// 📌 Firestore 저장
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

    await FirebaseFirestore.instance.collection('matches').add({
      'teamName': _teamNameController.text.trim(),
      'location': _locationController.text.trim(),
      'startTime': _startTimeController.text.trim(),
      'endTime': _endTimeController.text.trim(),
      'date': Timestamp.fromDate(_selectedDate!), // ✅ 매치 날짜
      'registerStart': Timestamp.fromDate(_registerStart!), // ✅ 등록 시작
      'registerEnd': Timestamp.fromDate(_registerEnd!), // ✅ 등록 종료
      'recruitStatus': 'confirmed', // 기본 상태
      'createdAt': FieldValue.serverTimestamp(), // 생성 시각
    });

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('✅ 매치가 등록되었습니다.')));
    }
  }

  @override
  void dispose() {
    _teamNameController.dispose();
    _locationController.dispose();
    _startTimeController.dispose();
    _endTimeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('➕ 매치 등록')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
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

            // 📅 매치 날짜
            Row(
              children: [
                Expanded(
                  child: Text(
                    _selectedDate == null
                        ? '📅 매치 날짜 선택 안됨'
                        : '매치 날짜: ${_selectedDate!.toLocal()}',
                  ),
                ),
                TextButton(
                  onPressed: () => _pickMatchDate(context),
                  child: const Text('매치 날짜 선택'),
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
                onPressed: _saveMatch,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
