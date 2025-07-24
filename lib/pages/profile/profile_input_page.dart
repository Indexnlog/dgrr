import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart' as p;

import '../../widgets/custom_text_field.dart'; // 공통 텍스트필드
import '../../widgets/primary_button.dart'; // 공통 버튼

class ProfileInputPage extends StatefulWidget {
  final String uid; // 로그인한 사용자 UID
  const ProfileInputPage({Key? key, required this.uid}) : super(key: key);

  @override
  State<ProfileInputPage> createState() => _ProfileInputPageState();
}

class _ProfileInputPageState extends State<ProfileInputPage> {
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
  String? _currentPhotoUrl;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final doc = await FirebaseFirestore.instance
        .collection('members')
        .doc(widget.uid)
        .get();
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
        _currentPhotoUrl = data['photoUrl'];
      });
    }
  }

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
    final ext = p.extension(_selectedImage!.path);
    final ref = FirebaseStorage.instance.ref().child('profile_images/$uid$ext');
    await ref.putFile(_selectedImage!);
    return await ref.getDownloadURL();
  }

  Future<void> _saveProfile() async {
    // ✅ TextFormField validator가 없으니 여기서 간단한 필수 체크 가능
    if (_nameController.text.trim().isEmpty) {
      _showSnack('본명을 입력해주세요.');
      return;
    }
    if (_uniformNameController.text.trim().isEmpty) {
      _showSnack('유니폼 이름을 입력해주세요.');
      return;
    }

    setState(() => _saving = true);

    try {
      final number = int.tryParse(_numberController.text.trim()) ?? 0;
      final uniformName = _uniformNameController.text.trim();

      // 🔹 등번호 중복 체크
      final numberQuery = await FirebaseFirestore.instance
          .collection('members')
          .where('number', isEqualTo: number)
          .get();
      if (numberQuery.docs.any((doc) => doc.id != widget.uid)) {
        _showSnack('등번호 $number 는 이미 사용 중입니다.');
        setState(() => _saving = false);
        return;
      }

      // 🔹 유니폼 이름 중복 체크
      final uniformNameQuery = await FirebaseFirestore.instance
          .collection('members')
          .where('uniformName', isEqualTo: uniformName)
          .get();
      if (uniformNameQuery.docs.any((doc) => doc.id != widget.uid)) {
        _showSnack('유니폼 이름 "$uniformName" 은 이미 사용 중입니다.');
        setState(() => _saving = false);
        return;
      }

      final photoUrl = await _uploadProfileImage(widget.uid);

      final updateData = {
        'name': _nameController.text.trim(),
        'uniformName': uniformName,
        'number': number,
        'phone': _phoneController.text.trim(),
        'homeAddress': _homeAddressController.text.trim(),
        'workAddress': _workAddressController.text.trim(),
        'department': _department,
      };
      if (photoUrl != null) updateData['photoUrl'] = photoUrl;

      await FirebaseFirestore.instance
          .collection('members')
          .doc(widget.uid)
          .update(updateData);

      _showSnack('✅ 프로필이 수정되었습니다!');
      if (mounted) Navigator.pop(context);
    } catch (e) {
      _showSnack('❌ 수정 실패: $e');
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
              Center(
                child: GestureDetector(
                  onTap: _pickImage,
                  child: CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.grey[300],
                    backgroundImage: _selectedImage != null
                        ? FileImage(_selectedImage!)
                        : (_currentPhotoUrl != null
                                  ? NetworkImage(_currentPhotoUrl!)
                                  : null)
                              as ImageProvider?,
                    child: (_selectedImage == null && _currentPhotoUrl == null)
                        ? const Icon(
                            Icons.person,
                            size: 50,
                            color: Colors.white,
                          )
                        : null,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // 🔹 공통 텍스트필드
              CustomTextField(controller: _nameController, hintText: '본명'),
              const SizedBox(height: 16),

              CustomTextField(
                controller: _uniformNameController,
                hintText: '유니폼 이름',
              ),
              const SizedBox(height: 16),

              CustomTextField(
                controller: _numberController,
                hintText: '등번호',
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),

              CustomTextField(
                controller: _phoneController,
                hintText: '연락처 (숫자만 입력)',
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),

              CustomTextField(
                controller: _homeAddressController,
                hintText: '자택 주소 (구까지만)',
              ),
              const SizedBox(height: 16),

              CustomTextField(
                controller: _workAddressController,
                hintText: '직장 주소 (구까지만)',
              ),
              const SizedBox(height: 16),

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
              const SizedBox(height: 24),

              _saving
                  ? const Center(child: CircularProgressIndicator())
                  : PrimaryButton(text: '수정 완료', onPressed: _saveProfile),
            ],
          ),
        ),
      ),
    );
  }
}
