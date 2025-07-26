import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

class TeamAddPage extends StatefulWidget {
  const TeamAddPage({super.key});

  @override
  State<TeamAddPage> createState() => _TeamAddPageState();
}

class _TeamAddPageState extends State<TeamAddPage> {
  final _formKey = GlobalKey<FormState>();
  final _teamNameController = TextEditingController();
  final _managerNameController = TextEditingController();
  final _managerContactController = TextEditingController();

  Color _teamColor = Colors.blue;
  File? _logoFile;
  bool _isSaving = false;

  // HEX 변환
  String _colorToHex(Color color) {
    return '#${color.value.toRadixString(16).substring(2).toUpperCase()}';
  }

  Future<void> _pickLogo() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        _logoFile = File(picked.path);
      });
    }
  }

  Future<void> _saveTeam() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    String logoUrl = '';
    if (_logoFile != null) {
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.png';
      final ref = FirebaseStorage.instance.ref().child('team_logos/$fileName');
      await ref.putFile(_logoFile!);
      logoUrl = await ref.getDownloadURL();
    }

    final teamData = {
      'name': _teamNameController.text.trim(),
      'managerName': _managerNameController.text.trim(),
      'managerContact': _managerContactController.text.trim(),
      'teamColor': _colorToHex(_teamColor),
      'logoUrl': logoUrl,
      'createdAt': Timestamp.now(),
      'memo': '',
      'records': {'wins': 0, 'draws': 0, 'losses': 0},
    };

    final docRef = await FirebaseFirestore.instance
        .collection('teams')
        .add(teamData);

    debugPrint('✅ 팀 등록 완료: ${docRef.id}');

    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('팀이 등록되었습니다!')));
      Navigator.pop(context); // 등록 후 뒤로 가기
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('➕ 팀 등록')),
      body: _isSaving
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      controller: _teamNameController,
                      decoration: const InputDecoration(labelText: '팀 이름'),
                      validator: (v) =>
                          v == null || v.isEmpty ? '팀 이름을 입력하세요' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _managerNameController,
                      decoration: const InputDecoration(labelText: '담당자 이름'),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _managerContactController,
                      decoration: const InputDecoration(labelText: '담당자 연락처'),
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      '팀 컬러',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (ctx) {
                            return AlertDialog(
                              title: const Text('팀 컬러 선택'),
                              content: SingleChildScrollView(
                                child: ColorPicker(
                                  pickerColor: _teamColor,
                                  onColorChanged: (color) {
                                    setState(() => _teamColor = color);
                                  },
                                  enableAlpha: false,
                                  showLabel: true,
                                ),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx),
                                  child: const Text('확인'),
                                ),
                              ],
                            );
                          },
                        );
                      },
                      child: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: _teamColor,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade400),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      '팀 로고',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        ElevatedButton.icon(
                          onPressed: _pickLogo,
                          icon: const Icon(Icons.image),
                          label: const Text('로고 선택'),
                        ),
                        const SizedBox(width: 12),
                        if (_logoFile != null)
                          Image.file(_logoFile!, width: 48, height: 48),
                      ],
                    ),
                    const SizedBox(height: 32),
                    Center(
                      child: ElevatedButton.icon(
                        onPressed: _saveTeam,
                        icon: const Icon(Icons.save),
                        label: const Text('팀 등록'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
