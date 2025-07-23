import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProfileInputPage extends StatefulWidget {
  final String uid; // 로그인한 사용자 UID
  const ProfileInputPage({Key? key, required this.uid}) : super(key: key);

  @override
  State<ProfileInputPage> createState() => _ProfileInputPageState();
}

class _ProfileInputPageState extends State<ProfileInputPage> {
  final _formKey = GlobalKey<FormState>();

  // 컨트롤러
  final _nameController = TextEditingController();
  final _uniformNameController = TextEditingController();
  final _numberController = TextEditingController();
  final _phoneController = TextEditingController();
  final _homeAddressController = TextEditingController();
  final _workAddressController = TextEditingController();

  String _department = '미정';
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final doc = await FirebaseFirestore.instance.collection('members').doc(widget.uid).get();
    if (doc.exists) {
      final data = doc.data()!;
      setState(() {
        _nameController.text = data['name'] ?? '';
        _uniformNameController.text = data['uniformName'] ?? '';
        _numberController.text = (data['number'] ?? '').toString();
        _phoneController.text = data['phone'] ?? '';
        _homeAddressController.text = data['homeAddress'] ?? '';
        _workAddressController.text = data['workAddress'] ?? '';
        _department = data['department'] ?? '미정';
      });
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);

    try {
      final number = int.tryParse(_numberController.text.trim()) ?? 0;
      final uniformName = _uniformNameController.text.trim();

      // 등번호 중복 체크
      final numberQuery = await FirebaseFirestore.instance
          .collection('members')
          .where('number', isEqualTo: number)
          .get();
      final numberDuplicate = numberQuery.docs.any((doc) => doc.id != widget.uid);
      if (numberDuplicate) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('등번호 $number 는 이미 사용 중입니다.')),
        );
        setState(() => _saving = false);
        return;
      }

      // 유니폼 이름 중복 체크
      final uniformNameQuery = await FirebaseFirestore.instance
          .collection('members')
          .where('uniformName', isEqualTo: uniformName)
          .get();
      final uniformNameDuplicate = uniformNameQuery.docs.any((doc) => doc.id != widget.uid);
      if (uniformNameDuplicate) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('유니폼 이름 "$uniformName" 은 이미 사용 중입니다.')),
        );
        setState(() => _saving = false);
        return;
      }

      // Firestore 업데이트
      await FirebaseFirestore.instance.collection('members').doc(widget.uid).update({
        'name': _nameController.text.trim(),
        'uniformName': uniformName,
        'number': number,
        'phone': _phoneController.text.trim(),
        'homeAddress': _homeAddressController.text.trim(),
        'workAddress': _workAddressController.text.trim(),
        'department': _department,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ 프로필이 수정되었습니다!')),
      );

      if (mounted) Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ 수정 실패: $e')),
      );
    } finally {
      setState(() => _saving = false);
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
      appBar: AppBar(title: const Text('프로필 수정')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: '본명'),
                validator: (v) => (v == null || v.isEmpty) ? '본명을 입력하세요' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _uniformNameController,
                decoration: const InputDecoration(labelText: '유니폼 이름'),
                validator: (v) => (v == null || v.isEmpty) ? '유니폼 이름을 입력하세요' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _numberController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: '등번호'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  _PhoneNumberTextInputFormatter(), // ✅ 자동 하이픈
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
              TextFormField(
                controller: _homeAddressController,
                validator: (v) {
                  if (v == null || v.isEmpty) return '주소를 입력해주세요';
                  final parts = v.trim().split(' ');
                  if (parts.length > 2) return '구까지만 입력해주세요 (예: 서울특별시 영등포구)';
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
              TextFormField(
                controller: _workAddressController,
                validator: (v) {
                  if (v == null || v.isEmpty) return null;
                  final parts = v.trim().split(' ');
                  if (parts.length > 2) return '구까지만 입력해주세요 (예: 서울특별시 영등포구)';
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
              DropdownButtonFormField<String>(
                value: _department,
                items: const [
                  DropdownMenuItem(value: '운영팀', child: Text('운영팀')),
                  DropdownMenuItem(value: '수업관리팀', child: Text('수업관리팀')),
                  DropdownMenuItem(
                      value: '경기관리/대외협력팀', child: Text('경기관리/대외협력팀')),
                  DropdownMenuItem(value: '미정', child: Text('미정')),
                ],
                onChanged: (v) => setState(() => _department = v ?? '미정'),
                decoration: const InputDecoration(labelText: '소속'),
              ),
              const SizedBox(height: 24),
              _saving
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: _saveProfile,
                      child: const Text('수정 완료'),
                    ),
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
      TextEditingValue oldValue, TextEditingValue newValue) {
    final digitsOnly = newValue.text.replaceAll(RegExp(r'\D'), '');
    final buffer = StringBuffer();

    for (int i = 0; i < digitsOnly.length && i < 11; i++) {
      if (i == 3 || i == 7) buffer.write('-');
      buffer.write(digitsOnly[i]);
    }

    final formatted = buffer.toString();
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
