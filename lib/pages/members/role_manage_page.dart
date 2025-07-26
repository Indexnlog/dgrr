import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RoleManagePage extends StatefulWidget {
  final String memberUid; // 역할을 변경할 멤버의 Firestore 문서 ID
  const RoleManagePage({super.key, required this.memberUid});

  @override
  State<RoleManagePage> createState() => _RoleManagePageState();
}

class _RoleManagePageState extends State<RoleManagePage> {
  String _selectedRole = '일반회원'; // 기본값
  String _memberName = '';

  @override
  void initState() {
    super.initState();
    _loadCurrentRole();
  }

  Future<void> _loadCurrentRole() async {
    final doc = await FirebaseFirestore.instance
        .collection('members')
        .doc(widget.memberUid)
        .get();
    final data = doc.data();
    if (data != null) {
      setState(() {
        _selectedRole = data['role'] ?? '일반회원';
        _memberName = data['name'] ?? '';
      });
    }
  }

  Future<void> _saveRole() async {
    final docRef = FirebaseFirestore.instance
        .collection('members')
        .doc(widget.memberUid);

    // 기존 role 가져오기
    final doc = await docRef.get();
    final oldRole = doc.data()?['role'] ?? '일반회원';

    // role 업데이트
    await docRef.update({'role': _selectedRole});

    // 로그 기록
    await docRef.collection('logs').add({
      'field': 'role',
      'previousValue': oldRole,
      'newValue': _selectedRole,
      'changedAt': FieldValue.serverTimestamp(),
      'changedBy': FirebaseAuth.instance.currentUser?.uid,
    });

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ $_memberName 님의 역할이 $_selectedRole 로 변경되었습니다.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('역할 변경')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_memberName.isNotEmpty)
              Text(
                '대상: $_memberName',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            const SizedBox(height: 20),

            DropdownButtonFormField<String>(
              value: _selectedRole,
              items: const [
                DropdownMenuItem(value: '일반회원', child: Text('일반회원')),
                DropdownMenuItem(value: '운영팀', child: Text('운영팀')),
              ],
              onChanged: (v) {
                setState(() {
                  _selectedRole = v!;
                });
              },
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: '새로운 역할 선택',
              ),
            ),

            const SizedBox(height: 30),

            ElevatedButton.icon(
              icon: const Icon(Icons.save),
              label: const Text('역할 변경하기'),
              onPressed: _saveRole,
            ),
          ],
        ),
      ),
    );
  }
}
