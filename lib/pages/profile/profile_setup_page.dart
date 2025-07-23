import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

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
  bool _saving = false;

  // ✅ 프로필 이미지 관련
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  Future<String?> _uploadProfileImage(String uid) async {
    if (_selectedImage == null) return null;
    final ref = FirebaseStorage.instance.ref().child('profile_images/$uid.jpg');
    await ref.putFile(_selectedImage!);
    return await ref.getDownloadURL();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('로그인 상태가 아닙니다.')),
        );
        setState(() => _saving = false);
        return;
      }

      final number = int.tryParse(_numberController.text.trim()) ?? 0;
      final uniformName = _uniformNameController.text.trim();

      // 등번호 중복 체크
      final numberQuery = await FirebaseFirestore.instance
          .collection('members')
          .where('number', isEqualTo: number)
          .get();
      if (numberQuery.docs.any((doc) => doc.id != user.uid)) {
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
      if (uniformNameQuery.docs.any((doc) => doc.id != user.uid)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('유니폼 이름 "$uniformName" 은 이미 사용 중입니다.')),
        );
        setState(() => _saving = false);
        return;
      }

      // ✅ 프로필 이미지 업로드
      final photoUrl = await _uploadProfileImage(user.uid);

      // Firestore 저장
      await FirebaseFirestore.instance.collection('members').doc(user.uid).set({
        'memberId': user.uid,
        'name': _nameController.text.trim(),
        'uniformName': uniformName,
        'number': number,
        'phone': _phoneController.text.trim(),
        'homeAddress': _homeAddressController.text.trim(),
        'workAddress': _workAddressController.text.trim(),
        'department': _department,
        'role': '일반회원',
        'joinedAt': FieldValue.serverTimestamp(),
        'status': 'pending',
        if (photoUrl != null) 'photoUrl': photoUrl,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ 가입 완료!')),
      );

      if (mounted) Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ 저장 실패: $e')),
      );
    } finally {
      setState(() => _saving = false);
    }
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
              // ✅ 프로필 이미지 선택
              Center(
                child: GestureDetector(
                  onTap: _pickImage,
                  child: CircleAvatar(
                    radius: 50,
                    backgroundImage: _selectedImage != null
                        ? FileImage(_selectedImage!)
                        : const AssetImage('assets/default_profile.png')
                            as ImageProvider,
                    child: Align(
                      alignment: Alignment.bottomRight,
                      child: CircleAvatar(
                        radius: 16,
                        backgroundColor: Colors.white,
                        child: const Icon(Icons.camera_alt, size: 18),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: '본명'),
                validator: (v) =>
                    (v == null || v.isEmpty) ? '본명을 입력하세요' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _uniformNameController,
                decoration: const InputDecoration(labelText: '유니폼 이름'),
                validator: (v) =>
                    (v == null || v.isEmpty) ? '유니폼 이름을 입력하세요' : null,
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
                  _PhoneNumberTextInputFormatter(),
                ],
                validator: (v) =>
                    (v == null || v.isEmpty) ? '연락처를 입력하세요' : null,
                decoration: InputDecoration(
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Text('연락처'),
                      SizedBox(width: 6),
                      Text('(숫자만 입력)',
                          style: TextStyle(fontSize: 12, color: Colors.grey)),
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
                  if (parts.length > 2) {
                    return '구까지만 입력해주세요 (예: 서울특별시 영등포구)';
                  }
                  return null;
                },
                decoration: const InputDecoration(labelText: '자택 주소'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _workAddressController,
                validator: (v) {
                  if (v == null || v.isEmpty) return null;
                  final parts = v.trim().split(' ');
                  if (parts.length > 2) {
                    return '구까지만 입력해주세요 (예: 서울특별시 영등포구)';
                  }
                  return null;
                },
                decoration: const InputDecoration(labelText: '직장 주소'),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _department,
                items: const [
                  DropdownMenuItem(value: '운영팀', child: Text('운영팀')),
                  DropdownMenuItem(value: '수업관리팀', child: Text('수업관리팀')),
                  DropdownMenuItem(
                      value: '경기관리/대외협력팀',
                      child: Text('경기관리/대외협력팀')),
                  DropdownMenuItem(value: '미정', child: Text('미정')),
                ],
                onChanged: (v) => setState(() => _department = v ?? '미정'),
                decoration: const InputDecoration(labelText: '소속'),
              ),
              const SizedBox(height: 24),
              _saving
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: _save,
                      child: const Text('가입 완료'),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}

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
