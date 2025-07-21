import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProfileInputPage extends StatefulWidget {
  final String uid; // 로그인한 사용자 UID
  const ProfileInputPage({Key? key, required this.uid}) : super(key: key);

  @override
  State<ProfileInputPage> createState() => _ProfileInputPageState();
}

class _ProfileInputPageState extends State<ProfileInputPage> {
  // 텍스트 필드 컨트롤러들
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _uniformNameController = TextEditingController();
  final TextEditingController _numberController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _homeController = TextEditingController();
  final TextEditingController _workController = TextEditingController();

  // 드롭다운: 담당
  String _selectedDepartment = '미정';
  final List<String> _departments = [
    '경기관리/대외협력팀',
    '수업관리팀',
    '운영팀',
    '미정',
  ];

  bool _saving = false;

  // Firestore에 저장
  Future<void> _saveProfile() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('이름을 입력해주세요.')),
      );
      return;
    }

    setState(() {
      _saving = true;
    });

    try {
      await FirebaseFirestore.instance.collection('members').doc(widget.uid).set({
        'memberId': widget.uid,
        'name': _nameController.text.trim(),
        'uniformName': _uniformNameController.text.trim(),
        'number': int.tryParse(_numberController.text.trim()) ?? 0,
        'phone': _phoneController.text.trim(),
        'homeAddress': _homeController.text.trim(),
        'workAddress': _workController.text.trim(),
        'department': _selectedDepartment,
        'role': '일반회원', // 기본값
        'joinedAt': FieldValue.serverTimestamp(),
        'status': 'pending',
        'memo': '',
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ 회원 정보가 저장되었습니다!')),
      );

      Navigator.pop(context); // 저장 후 홈으로 돌아가기
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ 저장 실패: $e')),
      );
    } finally {
      setState(() {
        _saving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('추가 정보 입력')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: '이름'),
            ),
            TextField(
              controller: _uniformNameController,
              decoration: const InputDecoration(labelText: '유니폼 이름'),
            ),
            TextField(
              controller: _numberController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: '등번호'),
            ),
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: '연락처'),
            ),
            TextField(
              controller: _homeController,
              decoration: const InputDecoration(labelText: '자택 주소'),
            ),
            TextField(
              controller: _workController,
              decoration: const InputDecoration(labelText: '직장 주소'),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedDepartment,
              items: _departments
                  .map((dept) => DropdownMenuItem(value: dept, child: Text(dept)))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  _selectedDepartment = value ?? '미정';
                });
              },
              decoration: const InputDecoration(labelText: '담당'),
            ),
            const SizedBox(height: 24),
            _saving
                ? const Center(child: CircularProgressIndicator())
                : SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _saveProfile,
                      child: const Text('저장하기'),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}
