import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:flutter_application_1/models/class_model.dart'; // 모델 경로에 맞게 수정

class ClassDetailPage extends StatefulWidget {
  final ClassModel classModel;

  const ClassDetailPage({super.key, required this.classModel});

  @override
  State<ClassDetailPage> createState() => _ClassDetailPageState();
}

class _ClassDetailPageState extends State<ClassDetailPage> {
  final TextEditingController _commentController = TextEditingController();
  User? _currentUser;

  @override
  void initState() {
    super.initState();
    _currentUser = FirebaseAuth.instance.currentUser;
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final classModel = widget.classModel;
    final attendance = classModel.attendance;
    final comments = classModel.comments;

    return Scaffold(
      appBar: AppBar(title: Text('📘 ${classModel.date} 수업')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            // 날짜 및 시간
            Text(
              '${classModel.date} (${classModel.startTime} ~ ${classModel.endTime})',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            // 장소
            Row(
              children: [
                const Icon(Icons.place),
                const SizedBox(width: 8),
                Text(classModel.location),
              ],
            ),
            const SizedBox(height: 12),

            // 등록기간
            Text(
              '등록기간: ${_formatTimestamp(classModel.registerStart)} ~ ${_formatTimestamp(classModel.registerEnd)}',
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 8),

            // 상태
            Text(
              '상태: ${classModel.status == 'cancelled' ? '취소됨' : '진행중'}',
              style: TextStyle(
                color: classModel.status == 'cancelled'
                    ? Colors.red
                    : Colors.green,
                fontWeight: FontWeight.bold,
              ),
            ),

            const Divider(height: 32),

            // 출석 요약
            if (attendance != null) ...[
              Text('출석 요약', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Text('출석: ${attendance.present}명 / 결석: ${attendance.absent}명'),
              const SizedBox(height: 12),

              // 참석자 리스트
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: attendance.attendees.map((attendee) {
                  return ListTile(
                    leading: Icon(
                      attendee.status == 'attending'
                          ? Icons.check_circle
                          : Icons.cancel,
                      color: attendee.status == 'attending'
                          ? Colors.green
                          : Colors.red,
                    ),
                    title: Text('ID: ${attendee.userId}'),
                    subtitle: Text(
                      attendee.reason.isNotEmpty
                          ? '사유: ${attendee.reason}'
                          : '사유 없음',
                    ),
                    trailing: Text(
                      _formatTimestamp(attendee.updatedAt),
                      style: const TextStyle(fontSize: 12),
                    ),
                  );
                }).toList(),
              ),

              const Divider(height: 32),
            ],

            // ✅ 출석 버튼
            if (_currentUser != null)
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.check),
                      label: const Text('출석'),
                      onPressed: () => _submitAttendance('attending'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.close),
                      label: const Text('결석'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                      ),
                      onPressed: () => _submitAttendance('absent'),
                    ),
                  ),
                ],
              ),

            const SizedBox(height: 32),

            // 댓글 목록
            Text(
              '댓글 (${comments.length})',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            ...comments.map(
              (comment) => ListTile(
                leading: const Icon(Icons.comment),
                title: Text(comment.text),
                subtitle: Text('작성자: ${comment.userId}'),
              ),
            ),

            const SizedBox(height: 24),

            // 댓글 작성창
            TextField(
              controller: _commentController,
              decoration: InputDecoration(
                hintText: '댓글을 입력하세요',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _submitComment,
                ),
                border: const OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTimestamp(Timestamp ts) {
    final dt = ts.toDate();
    return '${dt.year}-${_two(dt.month)}-${_two(dt.day)} ${_two(dt.hour)}:${_two(dt.minute)}';
  }

  String _two(int n) => n.toString().padLeft(2, '0');

  Future<void> _submitAttendance(String status) async {
    if (_currentUser == null) return;
    final userId = _currentUser!.uid;
    final classModel = widget.classModel;

    final docRef = FirebaseFirestore.instance
        .collection('teams')
        .doc(classModel.teamId)
        .collection('classes')
        .doc(classModel.id);

    final reason = status == 'absent' ? '미입력' : '';
    final attendee = {
      'userId': userId,
      'status': status,
      'reason': reason,
      'updatedAt': Timestamp.now(),
    };

    await docRef.update({
      'attendance.attendees': FieldValue.arrayUnion([attendee]),
      'attendance.present': status == 'attending'
          ? FieldValue.increment(1)
          : FieldValue.increment(0),
      'attendance.absent': status == 'absent'
          ? FieldValue.increment(1)
          : FieldValue.increment(0),
    });

    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('✅ $status 처리되었습니다')));
    }
  }

  Future<void> _submitComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty || _currentUser == null) return;

    final classModel = widget.classModel;
    final comment = {'userId': _currentUser!.uid, 'text': text};

    final docRef = FirebaseFirestore.instance
        .collection('teams')
        .doc(classModel.teamId)
        .collection('classes')
        .doc(classModel.id);

    await docRef.update({
      'comments': FieldValue.arrayUnion([comment]),
    });

    _commentController.clear();

    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('✅ 댓글이 등록되었습니다')));
    }
  }
}
