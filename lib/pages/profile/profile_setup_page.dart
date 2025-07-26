import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart' as p;

import '../../widgets/custom_text_field.dart'; // ✅ 공통 텍스트필드
import '../../widgets/primary_button.dart'; // ✅ 공통 버튼

class ProfileSetupPage extends StatefulWidget {
  const ProfileSetupPage({super.key});

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

  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();

  // ✅ 입단일 선택용 변수
  DateTime? _selectedJoinDate;

  // 이미지 선택
  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  // 입단일 선택
  Future<void> _pickJoinDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedJoinDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => _selectedJoinDate = picked);
    }
  }

  // 프로필 이미지 업로드
  Future<String?> _uploadProfileImage(String uid) async {
    if (_selectedImage == null) return null;
    final ext = p.extension(_selectedImage!.path);
    final ref = FirebaseStorage.instance.ref().child('profile_images/$uid$ext');
    await ref.putFile(_selectedImage!);
    return await ref.getDownloadURL();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedJoinDate == null) {
      _showSnack('입단일을 선택해주세요.');
      return;
    }

    setState(() => _saving = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('로그인 상태가 아닙니다.')));
        setState(() => _saving = false);
        return;
      }

      final number = int.tryParse(_numberController.text.trim()) ?? 0;
      final uniformName = _uniformNameController.text.trim();

      // 🔹 등번호 중복 체크
      final numberQuery = await FirebaseFirestore.instance
          .collection('members')
          .where('number', isEqualTo: number)
          .get();
      if (numberQuery.docs.any((doc) => doc.id != user.uid)) {
        _showSnack('등번호 $number 는 이미 사용 중입니다.');
        setState(() => _saving = false);
        return;
      }

      // 🔹 유니폼 이름 중복 체크
      final uniformNameQuery = await FirebaseFirestore.instance
          .collection('members')
          .where('uniformName', isEqualTo: uniformName)
          .get();
      if (uniformNameQuery.docs.any((doc) => doc.id != user.uid)) {
        _showSnack('유니폼 이름 "$uniformName" 은 이미 사용 중입니다.');
        setState(() => _saving = false);
        return;
      }

      final photoUrl = await _uploadProfileImage(user.uid);

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
        'status': 'pending',
        'joinDate': Timestamp.fromDate(_selectedJoinDate!), // ✅ 직접 입력한 입단일
        if (photoUrl != null) 'photoUrl': photoUrl,
      });

      _showSnack('✅ 가입 완료!');
      if (mounted) Navigator.pop(context);
    } catch (e) {
      _showSnack('❌ 저장 실패: $e');
    } finally {
      setState(() => _saving = false);
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
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
              // ✅ 프로필 이미지
              Center(
                child: GestureDetector(
                  onTap: _pickImage,
                  child: CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.grey[300],
                    backgroundImage: _selectedImage != null
                        ? FileImage(_selectedImage!)
                        : const AssetImage('assets/images/default_profile.png'),
                    child: (_selectedImage == null)
                        ? const Icon(
                            Icons.camera_alt,
                            size: 32,
                            color: Colors.white,
                          )
                        : null,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // ✅ 이름
              CustomTextField(
                controller: _nameController,
                hintText: '본명',
                validator: (v) =>
                    (v == null || v.isEmpty) ? '본명을 입력해주세요' : null,
              ),
              const SizedBox(height: 16),

              // ✅ 유니폼 이름
              CustomTextField(
                controller: _uniformNameController,
                hintText: '유니폼 이름',
                validator: (v) =>
                    (v == null || v.isEmpty) ? '유니폼 이름을 입력해주세요' : null,
              ),
              const SizedBox(height: 16),

              // ✅ 등번호
              CustomTextField(
                controller: _numberController,
                hintText: '등번호',
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),

              // ✅ 연락처
              CustomTextField(
                controller: _phoneController,
                hintText: '연락처 (숫자만 입력)',
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              ),
              const SizedBox(height: 16),

              // ✅ 자택 주소
              CustomTextField(
                controller: _homeAddressController,
                hintText: '자택 주소 (구까지만)',
              ),
              const SizedBox(height: 16),

              // ✅ 직장 주소
              CustomTextField(
                controller: _workAddressController,
                hintText: '직장 주소 (구까지만)',
              ),
              const SizedBox(height: 16),

              // ✅ 소속
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
                onChanged: (v) => setState(() => _department = v ?? '미정'),
                decoration: const InputDecoration(labelText: '소속'),
              ),
              const SizedBox(height: 16),

              // ✅ 입단일 선택
              ListTile(
                tileColor: Colors.grey[100],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                title: Text(
                  _selectedJoinDate != null
                      ? '${_selectedJoinDate!.year}-${_selectedJoinDate!.month.toString().padLeft(2, '0')}-${_selectedJoinDate!.day.toString().padLeft(2, '0')}'
                      : '입단일을 선택하세요',
                ),
                trailing: const Icon(Icons.calendar_today),
                onTap: _pickJoinDate,
              ),
              const SizedBox(height: 24),

              _saving
                  ? const Center(child: CircularProgressIndicator())
                  : PrimaryButton(text: '가입 완료', onPressed: _save),
            ],
          ),
        ),
      ),
    );
  }
}
