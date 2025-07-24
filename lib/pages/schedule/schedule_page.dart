import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/schedule_event_model.dart';
import '../../services/firestore/schedule_service.dart';
import '../../widgets/event_card.dart';

class SchedulePage extends StatefulWidget {
  const SchedulePage({super.key});

  @override
  State<SchedulePage> createState() => _SchedulePageState();
}

class _SchedulePageState extends State<SchedulePage> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  String _filterType = 'all'; // all, lesson, match
  String _searchKeyword = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('📅 일정'),
        actions: [
          // 🔎 검색창 아이콘 누르면 필드 노출하는 식으로 커스터마이즈 가능
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            onSelected: (value) {
              setState(() {
                _filterType = value;
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'all', child: Text('전체 보기')),
              const PopupMenuItem(value: 'lesson', child: Text('수업만 보기')),
              const PopupMenuItem(value: 'match', child: Text('매치만 보기')),
            ],
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              decoration: InputDecoration(
                hintText: '장소 검색',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 0,
                  horizontal: 8,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _searchKeyword = value.toLowerCase();
                });
              },
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // TODO: TableCalendar 추가 부분
          // ...

          // 일정 리스트
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream:
                  ScheduleService.getClassesStream(), // 👉 여기서 matches도 필요하면 합치는 로직 추가 가능
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData) {
                  return const Center(child: Text('데이터 없음'));
                }

                final docs = snapshot.data!.docs;
                List<ScheduleEvent> events = docs.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return ScheduleEvent.fromMap(data, doc.id);
                }).toList();

                // ✅ 1) 날짜 필터
                events = events.where((e) {
                  return _selectedDay == null ||
                      isSameDay(e.date, _selectedDay!);
                }).toList();

                // ✅ 2) 타입 필터
                if (_filterType != 'all') {
                  events = events.where((e) => e.type == _filterType).toList();
                }

                // ✅ 3) 검색어 필터
                if (_searchKeyword.isNotEmpty) {
                  events = events.where((e) {
                    return e.location.toLowerCase().contains(_searchKeyword);
                  }).toList();
                }

                if (events.isEmpty) {
                  return const Center(child: Text('일정이 없습니다.'));
                }

                return ListView.builder(
                  itemCount: events.length,
                  itemBuilder: (context, index) {
                    final event = events[index];
                    return EventCard(
                      event: event,
                      onAttend: () {
                        ScheduleService.updateAttendance(
                          collectionName: event.type == 'lesson'
                              ? 'classes'
                              : 'matches',
                          docId: event.id,
                          userId: '현재로그인아이디',
                          status: 'attending',
                        );
                      },
                      onAbsent: () {
                        ScheduleService.updateAttendance(
                          collectionName: event.type == 'lesson'
                              ? 'classes'
                              : 'matches',
                          docId: event.id,
                          userId: '현재로그인아이디',
                          status: 'absent',
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
