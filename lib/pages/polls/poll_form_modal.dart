import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'poll_model.dart';

class PollFormModal extends StatefulWidget {
  final void Function(PollModel poll) onSave;

  const PollFormModal({super.key, required this.onSave});

  @override
  State<PollFormModal> createState() => _PollFormModalState();
}

class _PollFormModalState extends State<PollFormModal> {
  final titleCtrl = TextEditingController();
  final List<TextEditingController> optionCtrls = [
    TextEditingController(),
    TextEditingController(),
  ];

  DateTime? selectedDate;

  void _addOptionField() {
    setState(() {
      optionCtrls.add(TextEditingController());
    });
  }

  void _submit() {
    final title = titleCtrl.text.trim();
    final options = optionCtrls
        .map((c) => c.text.trim())
        .where((text) => text.isNotEmpty)
        .toList();

    if (title.isEmpty || options.length < 2 || selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('질문, 옵션 2개 이상, 마감일을 입력해주세요')),
      );
      return;
    }

    final poll = PollModel(
      id: FirebaseFirestore.instance.collection('polls').doc().id,
      teamId: 'YOUR_TEAM_ID', // TODO: Provider에서 받아오기
      title: title,
      description: '',
      type: 'text',
      maxSelections: 1,
      canChangeVote: false,
      showResultBeforeDeadline: true,
      anonymous: false,
      linkedEventId: '',
      expiresAt: Timestamp.fromDate(selectedDate!),
      resultFinalizedAt: null,
      isActive: true,
      createdAt: Timestamp.now(),
      createdBy: 'YOUR_USER_ID', // TODO: 현재 로그인 유저 ID
      options: options.map((text) {
        return PollOption(
          id: UniqueKey().toString(),
          text: text,
          votes: [],
          voteCount: 0,
        );
      }).toList(),
    );

    widget.onSave(poll);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🗳 투표 추가', style: TextStyle(fontSize: 18)),
            const SizedBox(height: 12),
            TextField(
              controller: titleCtrl,
              decoration: const InputDecoration(labelText: '질문'),
            ),
            const SizedBox(height: 12),
            ...optionCtrls.map((ctrl) {
              final index = optionCtrls.indexOf(ctrl);
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: TextField(
                  controller: ctrl,
                  decoration: InputDecoration(labelText: '옵션 ${index + 1}'),
                ),
              );
            }),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: _addOptionField,
                icon: const Icon(Icons.add),
                label: const Text('옵션 추가'),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Text('마감일:'),
                const SizedBox(width: 8),
                Text(
                  selectedDate != null
                      ? '${selectedDate!.toLocal()}'.split(' ')[0]
                      : '선택 안됨',
                ),
                const Spacer(),
                TextButton(
                  onPressed: () async {
                    final now = DateTime.now();
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: now,
                      firstDate: now,
                      lastDate: now.add(const Duration(days: 365)),
                    );
                    if (picked != null) {
                      setState(() {
                        selectedDate = picked;
                      });
                    }
                  },
                  child: const Text('날짜 선택'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _submit,
              icon: const Icon(Icons.save),
              label: const Text('투표 생성'),
            ),
          ],
        ),
      ),
    );
  }
}
