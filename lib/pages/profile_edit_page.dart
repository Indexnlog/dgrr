import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ProfileEditPage extends StatefulWidget {
  final String docId; // Firestore 문서 ID

  const ProfileEditPage({Key? key, required this.docId}) : super(key: key);

  @override
  State<ProfileEditPage> createState() => _ProfileEditPageState();
}

class _ProfileEditPageState extends State<ProfileEditPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _uniformNameController = TextEditingController();
  final _numberController = TextEditingController();
  final _phoneController = TextEditingController();

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
      _nameController.text = data['name'] ?? '';
      _uniformNameController.text = data['uniformName'] ?? '';
      _numberController.text = (data['number'] ?? '').toString();
      _phoneController.text = data['phone'] ?? '';
    }
  }

  Future<void> _save() async {
    if (_formKey.currentState!.validate()) {
      await FirebaseFirestore.instance
          .collection('members')
          .doc(widget.docId)
          .update({
            'name': _nameController.text,
            'uniformName': _uniformNameController.text,
            'number': int.tryParse(_numberController.text) ?? 0,
            'phone': _phoneController.text,
          });
      if (!mounted) return;
      Navigator.pop(context); // 저장 후 뒤로가기
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
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: '이름'),
              ),
              TextFormField(
                controller: _uniformNameController,
                decoration: const InputDecoration(labelText: '유니폼 이름'),
              ),
              TextFormField(
                controller: _numberController,
                decoration: const InputDecoration(labelText: '등번호'),
              ),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(labelText: '연락처'),
              ),
              const SizedBox(height: 20),
              ElevatedButton(onPressed: _save, child: const Text('저장하기')),
            ],
          ),
        ),
      ),
    );
  }
}
