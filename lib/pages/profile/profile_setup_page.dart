import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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

  Future<void> _save() async {
    if (_formKey.currentState!.validate()) {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('로그인 상태가 아닙니다.')));
        return;
      }

      final number = int.tryParse(_numberController.text) ?? 0;
      final uniformName = _uniformNameController.text.trim();

      // 등번호 중복 체크
      final numberQuery = await FirebaseFirestore.instance
          .collection('members')
          .where('number', isEqualTo: number)
          .get();

      bool numberDuplicate = numberQuery.docs.any((doc) => doc.id != user.uid);

      if (numberDuplicate) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('등번호 $number 는 이미 사용 중입니다.')));
        return;
      }

      // 유니폼 이름 중복 체크 (대소문자 무시)
      final uniformNameQuery = await FirebaseFirestore.instance
          .collection('members')
          .where('uniformName', isEqualTo: uniformName)
          .get();

      bool uniformNameDuplicate = uniformNameQuery.docs.any(
        (doc) => doc.id != user.uid,
      );

      if (uniformNameDuplicate) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('유니폼 이름 "$uniformName" 은 이미 사용 중입니다.')),
        );
        return;
      }

      // 중복 없으면 저장
      await FirebaseFirestore.instance.collection('members').doc(user.uid).set({
        'memberId': user.uid,
        'name': _nameController.text,
        'uniformName': uniformName,
        'number': number,
        'phone': _phoneController.text,
        'homeAddress': _homeAddressController.text,
        'workAddress': _workAddressController.text,
        'department': _department,
        'role': '일반회원', // 가입 시 기본 역할
        'joinedAt': FieldValue.serverTimestamp(),
        'status': 'pending', // 가입 승인 대기 상태
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('저장 완료')));

      if (!mounted) return;
      Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _uniformNameController.dispose();
    _numberController.dispose();
    _phoneController.dispose();
    _homeAddressController.dispose();
    _workAddressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('프로필 설정')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // 본명
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: '본명'),
                validator: (v) => (v == null || v.isEmpty) ? '본명을 입력하세요' : null,
              ),

              const SizedBox(height: 16),

              // 유니폼 이름
              TextFormField(
                controller: _uniformNameController,
                decoration: const InputDecoration(labelText: '유니폼 이름'),
                validator: (v) =>
                    (v == null || v.isEmpty) ? '유니폼 이름을 입력하세요' : null,
              ),

              const SizedBox(height: 16),

              // 등번호
              TextFormField(
                controller: _numberController,
                decoration: const InputDecoration(labelText: '등번호'),
                keyboardType: TextInputType.number,
              ),

              const SizedBox(height: 16),

              // 연락처 + (숫자만 입력) 텍스트
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  _PhoneNumberTextInputFormatter(),
                ],
                validator: (v) => (v == null || v.isEmpty) ? '연락처를 입력하세요' : null,
                decoration: InputDecoration(
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Text('연락처'),
                      SizedBox(width: 6),
                      Text(
                        '(숫자만 입력)',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // 자택 주소 (구까지만 입력)
              TextFormField(
                controller: _homeAddressController,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '주소를 입력해주세요';
                  }
                  final parts = value.trim().split(' ');
                  if (parts.length > 2) {
                    return '구까지만 입력해주세요 (예: 서울특별시 영등포구)';
                  }
                  return null;
                },
                decoration: InputDecoration(
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Text('자택 주소'),
                      SizedBox(width: 6),
                      Text(
                        '(구까지만 입력)',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // 직장 주소 (구까지만 입력)
              TextFormField(
                controller: _workAddressController,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return null;
                  }
                  final parts = value.trim().split(' ');
                  if (parts.length > 2) {
                    return '구까지만 입력해주세요 (예: 서울특별시 영등포구)';
                  }
                  return null;
                },
                decoration: InputDecoration(
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Text('직장 주소'),
                      SizedBox(width: 6),
                      Text(
                        '(구까지만 입력)',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // 소속
              DropdownButtonFormField<String>(
                value: _department,
                items: const [
                  DropdownMenuItem(value: '운영팀', child: Text('운영팀')),
                  DropdownMenuItem(value: '수업관리팀', child: Text('수업관리팀')),
                  DropdownMenuItem(
                    value: '경기관리/대외협력팀',
                    child: Text('경기관리/대외협력팀'),
                  ),
                  DropdownMenuItem(value: '미정', child: Text('미정')),
                ],
                onChanged: (v) => setState(() => _department = v!),
                decoration: const InputDecoration(labelText: '소속'),
              ),

              const SizedBox(height: 24),

              ElevatedButton(onPressed: _save, child: const Text('가입 완료')),
            ],
          ),
        ),
      ),
    );
  }
}

/// 전화번호 자동 하이픈 입력 Formatter
class _PhoneNumberTextInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digitsOnly = newValue.text.replaceAll(RegExp(r'\D'), '');
    final buffer = StringBuffer();

    for (int i = 0; i < digitsOnly.length && i < 11; i++) {
      if (i == 3 || i == 7) {
        buffer.write('-');
      }
      buffer.write(digitsOnly[i]);
    }

    final formatted = buffer.toString();
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
