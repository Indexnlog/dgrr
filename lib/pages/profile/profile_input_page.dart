import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart' as p; // ✅ 확장자 추출용

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

  // 프로필 이미지
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

  /// 📌 이미지 선택
  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  /// 📌 Storage 업로드 후 URL 리턴
  Future<String?> _uploadProfileImage(String uid) async {
    if (_selectedImage == null) return null;
    final ext = p.extension(_selectedImage!.path); // ✅ 확장자 유지
    final ref = FirebaseStorage.instance.ref().child('profile_images/$uid$ext');
    await ref.putFile(_selectedImage!);
    return await ref.getDownloadURL();
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
      if (numberQuery.docs.any((doc) => doc.id != widget.uid)) {
        _showSnack('등번호 $number 는 이미 사용 중입니다.');
        setState(() => _saving = false);
        return;
      }

      // 유니폼 이름 중복 체크
      final uniformNameQuery = await FirebaseFirestore.instance
          .collection('members')
          .where('uniformName', isEqualTo: uniformName)
          .get();
      if (uniformNameQuery.docs.any((doc) => doc.id != widget.uid)) {
        _showSnack('유니폼 이름 "$uniformName" 은 이미 사용 중입니다.');
        setState(() => _saving = false);
        return;
      }

      // 프로필 이미지 업로드
      final photoUrl = await _uploadProfileImage(widget.uid);

      // Firestore 업데이트
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
              _buildTextField(_nameController, '본명', validator: true),
              const SizedBox(height: 16),
              _buildTextField(
                _uniformNameController,
                '유니폼 이름',
                validator: true,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                _numberController,
                '등번호',
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              _buildPhoneField(),
              const SizedBox(height: 16),
              _buildAddressField(_homeAddressController, '자택 주소', true),
              const SizedBox(height: 16),
              _buildAddressField(_workAddressController, '직장 주소', false),
              const SizedBox(height: 16),
              _buildDropdown(),
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

  Widget _buildTextField(
    TextEditingController controller,
    String label, {
    bool validator = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(labelText: label),
      validator: validator
          ? (v) => (v == null || v.isEmpty) ? '$label 을(를) 입력하세요' : null
          : null,
    );
  }

  Widget _buildPhoneField() {
    return TextFormField(
      controller: _phoneController,
      keyboardType: TextInputType.number,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        _PhoneNumberTextInputFormatter(),
      ],
      validator: (v) => (v == null || v.isEmpty) ? '연락처를 입력하세요' : null,
      decoration: const InputDecoration(
        labelText: '연락처',
        helperText: '(숫자만 입력)',
      ),
    );
  }

  Widget _buildAddressField(
    TextEditingController controller,
    String label,
    bool required,
  ) {
    return TextFormField(
      controller: controller,
      validator: (v) {
        if (!required && (v == null || v.isEmpty)) return null;
        if (v == null || v.isEmpty) return '$label을 입력해주세요';
        final parts = v.trim().split(' ');
        if (parts.length > 2) return '구까지만 입력해주세요 (예: 서울특별시 영등포구)';
        return null;
      },
      decoration: InputDecoration(labelText: '$label (구까지만 입력)'),
    );
  }

  Widget _buildDropdown() {
    return DropdownButtonFormField<String>(
      value: _department,
      items: const [
        DropdownMenuItem(value: '운영팀', child: Text('운영팀')),
        DropdownMenuItem(value: '수업관리팀', child: Text('수업관리팀')),
        DropdownMenuItem(value: '경기관리/대외협력팀', child: Text('경기관리/대외협력팀')),
        DropdownMenuItem(value: '미정', child: Text('미정')),
      ],
      onChanged: (v) => setState(() => _department = v ?? '미정'),
      decoration: const InputDecoration(labelText: '소속'),
    );
  }
}

/// 📌 전화번호 자동 하이픈 입력 Formatter
class _PhoneNumberTextInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
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
