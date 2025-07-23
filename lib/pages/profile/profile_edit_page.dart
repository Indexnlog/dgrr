import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ProfileEditPage extends StatefulWidget {
  final String docId;

  const ProfileEditPage({Key? key, required this.docId}) : super(key: key);

  @override
  State<ProfileEditPage> createState() => _ProfileEditPageState();
}

class _ProfileEditPageState extends State<ProfileEditPage> {
  final _formKey = GlobalKey<FormState>();

  // 🔹 본명(name)은 수정 불가
  String _name = '';

  // 🔹 수정 가능한 필드
  final _uniformNameController = TextEditingController();
  final _numberController = TextEditingController();
  final _phoneController = TextEditingController();

  // 🔹 Dropdown 선택값
  String _department = '미정';
  String _role = '일반회원';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final doc = await FirebaseFirestore.instance
        .collection('members')
        .doc(widget.docId)
        .get();

    final data = doc.data();
    if (data != null) {
      _name = data['name'] ?? ''; // 본명
      _uniformNameController.text = data['uniformName'] ?? '';
      _numberController.text = (data['number'] ?? '').toString();
      _phoneController.text = data['phone'] ?? '';
      _department = data['department'] ?? '미정';
      _role = data['role'] ?? '일반회원';
      setState(() {});
    }
  }

  Future<void> _save() async {
    if (_formKey.currentState!.validate()) {
      await FirebaseFirestore.instance
          .collection('members')
          .doc(widget.docId)
          .update({
        'uniformName': _uniformNameController.text,
        'number': int.tryParse(_numberController.text) ?? 0,
        'phone': _phoneController.text,
        'department': _department,
        'role': _role,
      });
      if (!mounted) return;
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('회원 정보 수정')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // 본명은 읽기 전용
              TextFormField(
                initialValue: _name,
                decoration: const InputDecoration(labelText: '본명'),
                readOnly: true,
              ),
              // 유니폼 이름
              TextFormField(
                controller: _uniformNameController,
                decoration: const InputDecoration(labelText: '유니폼 이름'),
                validator: (v) =>
                    (v == null || v.isEmpty) ? '유니폼 이름을 입력하세요' : null,
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
              // 🔻 담당 부서 선택
              DropdownButtonFormField<String>(
                value: _department,
                items: const [
                  DropdownMenuItem(value: '운영팀', child: Text('운영팀')),
                  DropdownMenuItem(value: '수업관리팀', child: Text('수업관리팀')),
                  DropdownMenuItem(
                      value: '경기관리/대외협력팀', child: Text('경기관리/대외협력팀')),
                  DropdownMenuItem(value: '미정', child: Text('미정')),
                ],
                onChanged: (v) => setState(() => _department = v!),
                decoration: const InputDecoration(labelText: '담당'),
              ),
              // 🔻 역할 부분 수정
              TextFormField(
                initialValue: _role,
                decoration: const InputDecoration(labelText: '역할(관리자 지정)'),
                readOnly: true, // 수정 불가
              ),

              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _save,
                child: const Text('저장하기'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
