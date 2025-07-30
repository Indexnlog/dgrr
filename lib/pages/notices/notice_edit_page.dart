import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class NoticeEditPage extends StatefulWidget {
  final String postId; // 관리 페이지에서 넘겨주는 문서 ID
  const NoticeEditPage({super.key, required this.postId});

  @override
  State<NoticeEditPage> createState() => _NoticeEditPageState();
}

class _NoticeEditPageState extends State<NoticeEditPage> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  bool _isPinned = false;
  DateTime? _publishAt;

  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchPostData();
  }

  Future<void> _fetchPostData() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('posts')
          .doc(widget.postId)
          .get();

      if (!doc.exists) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('❌ 해당 공지를 찾을 수 없습니다.')));
          Navigator.pop(context);
        }
        return;
      }

      final data = doc.data()!;
      setState(() {
        _titleController.text = data['title'] ?? '';
        _contentController.text = data['content'] ?? '';
        _isPinned = data['isPinned'] ?? false;
        _publishAt = data['publishAt'] != null
            ? (data['publishAt'] as Timestamp).toDate()
            : DateTime.now();
        _loading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('데이터 불러오기 오류: $e')));
        Navigator.pop(context);
      }
    }
  }

  Future<void> _pickDateTime(BuildContext context) async {
    final date = await showDatePicker(
      context: context,
      initialDate: _publishAt ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
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

  Future<void> _updateNotice() async {
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();

    if (title.isEmpty || content.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('제목과 내용을 입력해주세요.')));
      return;
    }

    try {
      await FirebaseFirestore.instance
          .collection('posts')
          .doc(widget.postId)
          .update({
            'title': title,
            'content': content,
            'isPinned': _isPinned,
            'publishAt': _publishAt != null
                ? Timestamp.fromDate(_publishAt!)
                : Timestamp.now(),
            'updatedAt': Timestamp.now(),
          });

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('✅ 공지가 수정되었습니다.')));
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('수정 오류: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('✏️ 공지 수정'),
        actions: [
          IconButton(icon: const Icon(Icons.save), onPressed: _updateNotice),
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
                  onPressed: _updateNotice,
                  icon: const Icon(Icons.save),
                  label: const Text('공지 수정하기'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
