import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/match_event_model.dart';

class MatchPage extends StatefulWidget {
  const MatchPage({super.key});

  @override
  State<MatchPage> createState() => _MatchPageState();
}

class _MatchPageState extends State<MatchPage> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('⚽ 매치'),
      ),
      body: Column(
        children: [
          // 🗓️ 날짜 선택 (필요시 TableCalendar 추가 가능)
          // 여기서는 간단히 필터링만
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                ElevatedButton(
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _focusedDay,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2030),
                    );
                    if (picked != null) {
                      setState(() {
                        _selectedDay = picked;
                        _focusedDay = picked;
                      });
                    }
                  },
                  child: Text(_selectedDay == null
                      ? '날짜 선택'
                      : '${_selectedDay!.year}-${_selectedDay!.month}-${_selectedDay!.day}'),
                ),
                const SizedBox(width: 8),
                if (_selectedDay != null)
                  IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      setState(() {
                        _selectedDay = null;
                      });
                    },
                  ),
              ],
            ),
          ),

          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('matches') // ✅ matches 컬렉션 구독
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('등록된 매치가 없습니다.'));
                }

                // Firestore → MatchEvent
                final allMatches = <MatchEvent>[];
                for (final doc in snapshot.data!.docs) {
                  final data = doc.data() as Map<String, dynamic>;
                  try {
                    final match = MatchEvent.fromMap(data, doc.id);
                    allMatches.add(match);
                  } catch (e) {
                    print('❌ [fromMap 오류] matches ${doc.id}: $e');
                  }
                }

                // 날짜 필터링
                final filteredMatches = allMatches.where((m) {
                  if (_selectedDay == null) return true;
                  return m.date.year == _selectedDay!.year &&
                      m.date.month == _selectedDay!.month &&
                      m.date.day == _selectedDay!.day;
                }).toList();

                if (filteredMatches.isEmpty) {
                  return const Center(child: Text('해당 날짜에 매치가 없습니다.'));
                }

                return ListView.builder(
                  itemCount: filteredMatches.length,
                  itemBuilder: (context, index) {
                    final match = filteredMatches[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      child: ListTile(
                        leading: const Icon(Icons.sports_soccer,
                            color: Colors.green),
                        title: Text(
                          '${match.time ?? ''} @ ${match.location ?? ''}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('상대팀: ${match.teamName ?? '-'}'),
                            Text(
                                '점수: ${match.score['home']} - ${match.score['away']}'),
                            Text('참석자: ${match.participants.length}'),
                          ],
                        ),
                        onTap: () {
                          // 👉 상세 페이지로 이동하고 싶다면 여기에 Navigator.push 추가
                          // Navigator.push(
                          //   context,
                          //   MaterialPageRoute(
                          //     builder: (context) => MatchDetailPage(matchId: match.id),
                          //   ),
                          // );
                        },
                      ),
