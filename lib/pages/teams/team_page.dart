import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

class TeamPage extends StatefulWidget {
  const TeamPage({super.key});
  @override
  State<TeamPage> createState() => _TeamPageState();
}

class _TeamPageState extends State<TeamPage> {
  // 헥스 변환
  String _colorToHex(Color color) {
    return '#${color.value.toRadixString(16).substring(2).toUpperCase()}';
  }

  Color _hexToColor(String? hex) {
    if (hex == null || hex.isEmpty) return Colors.grey.shade300;
    final buffer = StringBuffer();
    if (hex.length == 6 || hex.length == 7) buffer.write('ff');
    buffer.write(hex.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }

  // ✅ 팀 등록/수정 모달
  void _openTeamModal({String? teamId, Map<String, dynamic>? initialData}) {
    Color pickerColor = initialData != null && initialData['teamColor'] != null
        ? _hexToColor(initialData['teamColor'])
        : Colors.blue;
    final nameCtrl = TextEditingController(
      text: initialData != null ? initialData['name'] : '',
    );
    final managerCtrl = TextEditingController(
      text: initialData != null ? initialData['managerName'] : '',
    );
    final contactCtrl = TextEditingController(
      text: initialData != null ? initialData['managerContact'] : '',
    );
    File? logoFile;
    String logoUrl = initialData != null ? (initialData['logoUrl'] ?? '') : '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setStateModal) {
            Future<void> _pickLogo() async {
              final picked = await ImagePicker().pickImage(
                source: ImageSource.gallery,
              );
              if (picked != null) {
                setStateModal(() {
                  logoFile = File(picked.path);
                });
              }
            }

            Future<void> _saveTeam() async {
              if (nameCtrl.text.trim().isEmpty) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('팀 이름을 입력하세요')));
                return;
              }

              String newLogoUrl = logoUrl;
              if (logoFile != null) {
                final fileName = '${DateTime.now().millisecondsSinceEpoch}.png';
                final ref = FirebaseStorage.instance.ref().child(
                  'team_logos/$fileName',
                );
                await ref.putFile(logoFile!);
                newLogoUrl = await ref.getDownloadURL();
              }

              final data = {
                'name': nameCtrl.text.trim(),
                'managerName': managerCtrl.text.trim(),
                'managerContact': contactCtrl.text.trim(),
                'teamColor': _colorToHex(pickerColor),
                'logoUrl': newLogoUrl,
                'memo': initialData?['memo'] ?? '',
                'records':
                    initialData?['records'] ??
                    {'wins': 0, 'draws': 0, 'losses': 0},
                'createdAt': initialData?['createdAt'] ?? Timestamp.now(),
              };

              if (teamId == null) {
                await FirebaseFirestore.instance.collection('teams').add(data);
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('팀이 등록되었습니다!')));
              } else {
                await FirebaseFirestore.instance
                    .collection('teams')
                    .doc(teamId)
                    .update(data);
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('팀 정보가 수정되었습니다!')));
              }

              if (mounted) Navigator.pop(ctx);
            }

            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 16,
                bottom: MediaQuery.of(context).viewInsets.bottom + 16,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(labelText: '팀 이름'),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: managerCtrl,
                      decoration: const InputDecoration(labelText: '담당자 이름'),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: contactCtrl,
                      decoration: const InputDecoration(labelText: '담당자 연락처'),
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Text('팀 컬러:'),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () {
                            showDialog(
                              context: context,
                              builder: (dCtx) {
                                return AlertDialog(
                                  title: const Text('팀 컬러 선택'),
                                  content: SingleChildScrollView(
                                    child: ColorPicker(
                                      pickerColor: pickerColor,
                                      onColorChanged: (c) {
                                        setStateModal(() {
                                          pickerColor = c;
                                        });
                                      },
                                      enableAlpha: false,
                                    ),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(dCtx),
                                      child: const Text('확인'),
                                    ),
                                  ],
                                );
                              },
                            );
                          },
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: pickerColor,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: Colors.grey.shade400),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        ElevatedButton.icon(
                          onPressed: _pickLogo,
                          icon: const Icon(Icons.image),
                          label: const Text('로고 선택'),
                        ),
                        const SizedBox(width: 8),
                        if (logoFile != null)
                          Image.file(logoFile!, width: 40, height: 40)
                        else if (logoUrl.isNotEmpty)
                          Image.network(logoUrl, width: 40, height: 40),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _saveTeam,
                      icon: const Icon(Icons.save),
                      label: const Text('저장'),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('팀 관리'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: '팀 추가',
            onPressed: () => _openTeamModal(),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('teams')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('등록된 팀이 없습니다.'));
          }

          final teams = snapshot.data!.docs;

          return ListView.builder(
            itemCount: teams.length,
            itemBuilder: (context, index) {
              final doc = teams[index];
              final data = doc.data() as Map<String, dynamic>;
              final teamColor = _hexToColor(data['teamColor']);
              final logoUrl = data['logoUrl'] ?? '';
              final name = data['name'] ?? '';
              final managerName = data['managerName'] ?? '';
              final managerContact = data['managerContact'] ?? '';
              final records = data['records'] as Map<String, dynamic>? ?? {};
              final wins = records['wins'] ?? 0;
              final draws = records['draws'] ?? 0;
              final losses = records['losses'] ?? 0;

              return GestureDetector(
                onLongPress: () async {
                  final action = await showModalBottomSheet<String>(
                    context: context,
                    builder: (ctx) {
                      return SafeArea(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ListTile(
                              leading: const Icon(Icons.edit),
                              title: const Text('팀 수정'),
                              onTap: () => Navigator.pop(ctx, 'edit'),
                            ),
                            ListTile(
                              leading: const Icon(
                                Icons.delete,
                                color: Colors.red,
                              ),
                              title: const Text('팀 삭제'),
                              onTap: () => Navigator.pop(ctx, 'delete'),
                            ),
                          ],
                        ),
                      );
                    },
                  );

                  if (action == 'edit') {
                    _openTeamModal(teamId: doc.id, initialData: data);
                  } else if (action == 'delete') {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('삭제 확인'),
                        content: Text('정말 "$name" 팀을 삭제하시겠습니까?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, false),
                            child: const Text('취소'),
                          ),
                          ElevatedButton(
                            onPressed: () => Navigator.pop(ctx, true),
                            child: const Text('삭제'),
                          ),
                        ],
                      ),
                    );
                    if (confirm == true) {
                      await FirebaseFirestore.instance
                          .collection('teams')
                          .doc(doc.id)
                          .delete();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('팀이 삭제되었습니다.')),
                        );
                      }
                    }
                  }
                },
                child: Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: teamColor, width: 2),
                  ),
                  child: ListTile(
                    leading: logoUrl.isNotEmpty
                        ? CircleAvatar(
                            backgroundImage: NetworkImage(logoUrl),
                            backgroundColor: teamColor.withOpacity(0.2),
                          )
                        : CircleAvatar(
                            backgroundColor: teamColor,
                            child: const Icon(
                              Icons.groups,
                              color: Colors.white,
                            ),
                          ),
                    title: Text(
                      name,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (managerName.isNotEmpty)
                          Text('담당자: $managerName (${managerContact})'),
                        Text('전적: $wins승 $draws무 $losses패'),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
