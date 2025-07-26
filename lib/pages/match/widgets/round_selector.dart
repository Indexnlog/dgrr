import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RoundSelector extends StatefulWidget {
  final String matchId;
  final ValueChanged<String> onSelected; // 선택된 라운드 ID 전달

  const RoundSelector({
    super.key,
    required this.matchId,
    required this.onSelected,
  });

  @override
  State<RoundSelector> createState() => _RoundSelectorState();
}

class _RoundSelectorState extends State<RoundSelector> {
  String? _selectedRoundId;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('matches')
          .doc(widget.matchId)
          .collection('rounds')
          .orderBy('roundNumber', descending: false) // roundNumber 필드로 정렬
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(16.0),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text('등록된 라운드가 없습니다.'),
          );
        }

        final rounds = snapshot.data!.docs;

        // 기본 선택 (최초 한 번만)
        if (_selectedRoundId == null && rounds.isNotEmpty) {
          _selectedRoundId = rounds.first.id;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            widget.onSelected(_selectedRoundId!);
          });
        }

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            children: [
              const Text(
                '라운드 선택: ',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButton<String>(
                  isExpanded: true,
                  value: _selectedRoundId,
                  items: rounds.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final roundNumber = data['roundNumber'] ?? '';
                    final status = data['status'] ?? '';
                    return DropdownMenuItem<String>(
                      value: doc.id,
                      child: Text('라운드 $roundNumber ($status)'),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val == null) return;
                    setState(() {
                      _selectedRoundId = val;
                    });
                    widget.onSelected(val);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
