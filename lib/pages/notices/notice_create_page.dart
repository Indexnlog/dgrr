import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class NoticeCreatePage extends StatefulWidget {
  const NoticeCreatePage({super.key});

  @override
  State<NoticeCreatePage> createState() => _NoticeCreatePageState();
}

class _NoticeCreatePageState extends State<NoticeCreatePage> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  bool _isPinned = false;
  DateTime? _publishAt;

  Future<void> _pickDateTime(BuildContext context) async {
    final date = await showDatePicker(
      context: context,
      initialDate: _publishAt ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    if (date == null) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_publishAt ?? DateTime.now()),
    );
    if (time == null) return;

    setState(() {
      _publishAt = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  Future<void> _saveNotice() async {
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();

    if (title.isEmpty || content.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('제목과 내용을 입력해주세요.')));
      return;
    }

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('로그인 정보가 없습니다.')));
      return;
    }

    try {
      await FirebaseFirestore.instance.collection('posts').add({
        'title': title,
        'content': content,
        'isPinned': _isPinned,
        'publishAt': _publishAt != null
            ? Timestamp.fromDate(_publishAt!)
            : Timestamp.now(),
        'authorId': uid,
        'category': '공지',
        'createdAt': Timestamp.now(),
      });

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('✅ 공지가 등록되었습니다.')));
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('등록 오류: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('➕ 공지 등록'),
        actions: [
          IconButton(icon: const Icon(Icons.save), onPressed: _saveNotice),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: '제목',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _contentController,
                maxLines: 6,
                decoration: const InputDecoration(
                  labelText: '내용',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('홈 상단 고정 (isPinned)'),
                value: _isPinned,
                onChanged: (val) {
                  setState(() {
                    _isPinned = val;
                  });
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Text('📅 예약시간: '),
                  Expanded(
                    child: Text(
                      _publishAt != null
                          ? _publishAt!.toLocal().toString()
                          : '즉시 게시',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  TextButton(
                    onPressed: () => _pickDateTime(context),
                    child: const Text('변경'),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _saveNotice,
                  icon: const Icon(Icons.save),
                  label: const Text('공지 등록하기'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
