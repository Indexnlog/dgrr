import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ProfileSetupPage extends StatefulWidget {
  const ProfileSetupPage({Key? key}) : super(key: key);

  @override
  State<ProfileSetupPage> createState() => _ProfileSetupPageState();
}

class _ProfileSetupPageState extends State<ProfileSetupPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _uniformNameController = TextEditingController();
  final _numberController = TextEditingController();
  final _phoneController = TextEditingController();
  final _homeAddressController = TextEditingController();
  final _workAddressController = TextEditingController();
  String _department = '미정';

  Future<void> _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      await FirebaseFirestore.instance.collection('members').doc(uid).set({
        'memberId': uid,
        'name': _nameController.text,
        'uniformName': _uniformNameController.text,
        'number': int.tryParse(_numberController.text) ?? 0,
        'phone': _phoneController.text,
        'homeAddress': _homeAddressController.text,
        'workAddress': _workAddressController.text,
        'department': _department,
        'role': '일반회원',
        'joinedAt': FieldValue.serverTimestamp(),
        'status': 'active',
      });

      if (!mounted) return;
      Navigator.pop(context); // 저장 후 홈으로 돌아가기
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('추가 정보 입력')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: '이름'),
                validator: (v) => v == null || v.isEmpty ? '이름을 입력하세요' : null,
              ),
              TextFormField(
                controller: _uniformNameController,
                decoration: const InputDecoration(labelText: '유니폼 이름'),
              ),
              TextFormField(
                controller: _numberController,
                decoration: const InputDecoration(labelText: '등번호'),
                keyboardType: TextInputType.number,
              ),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(labelText: '연락처'),
              ),
              TextFormField(
                controller: _homeAddressController,
                decoration: const InputDecoration(labelText: '자택 주소'),
              ),
              TextFormField(
                controller: _workAddressController,
                decoration: const InputDecoration(labelText: '직장 주소'),
              ),
              DropdownButtonFormField<String>(
                value: _department,
                items: const [
                  DropdownMenuItem(
                    value: '경기관리/대외협력팀',
                    child: Text('경기관리/대외협력팀'),
                  ),
                  DropdownMenuItem(value: '수업관리팀', child: Text('수업관리팀')),
                  DropdownMenuItem(value: '운영팀', child: Text('운영팀')),
                  DropdownMenuItem(value: '미정', child: Text('미정')),
                ],
                onChanged: (value) => setState(() => _department = value!),
                decoration: const InputDecoration(labelText: '담당'),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _saveProfile,
                child: const Text('저장하기'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
