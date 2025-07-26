import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/schedule_event_model.dart';
import 'widgets/event_card.dart';

class SchedulePage extends StatefulWidget {
  const SchedulePage({super.key});

  @override
  State<SchedulePage> createState() => _SchedulePageState();
}

class _SchedulePageState extends State<SchedulePage> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  String _filterType = 'all'; // all, lesson, mt, dinner

  @override
  void initState() {
    super.initState();

    // ✅ Firestore classes 컬렉션 원본 데이터 출력
    FirebaseFirestore.instance
        .collection('classes')
        .get()
        .then((snapshot) {
          for (final doc in snapshot.docs) {
            print('🔥 [RAW DATA] ${doc.id}: ${doc.data()}');
          }
        })
        .catchError((e) {
          print('❌ Firestore 가져오기 오류: $e');
        });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('📅 일정'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            onSelected: (value) {
              setState(() {
                _filterType = value;
              });
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'all', child: Text('전체 보기')),
              PopupMenuItem(value: 'lesson', child: Text('수업만 보기')),
              PopupMenuItem(value: 'mt', child: Text('MT만 보기')),
              PopupMenuItem(value: 'dinner', child: Text('회식만 보기')),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // 📅 달력
          TableCalendar(
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) {
              return _selectedDay != null &&
                  day.year == _selectedDay!.year &&
                  day.month == _selectedDay!.month &&
                  day.day == _selectedDay!.day;
            },
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
            },
            calendarFormat: CalendarFormat.month,
            calendarStyle: const CalendarStyle(
              todayDecoration: BoxDecoration(
                color: Colors.orange,
                shape: BoxShape.circle,
              ),
              selectedDecoration: BoxDecoration(
                color: Colors.blue,
                shape: BoxShape.circle,
              ),
            ),
          ),

          const SizedBox(height: 8),

          // 📋 Firestore 일정 리스트
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('classes')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('일정이 없습니다.'));
                }

                final allEvents = <ScheduleEvent>[];
                for (final doc in snapshot.data!.docs) {
                  final data = doc.data() as Map<String, dynamic>;
                  try {
                    final event = ScheduleEvent.fromMap(data, doc.id);
                    allEvents.add(event);
                  } catch (e) {
                    // 🔥 fromMap 오류 확인
                    print('❌ [fromMap 오류] 문서 ${doc.id}: $e');
                  }
                }

                // 🔎 필터 적용
                final filteredEvents = allEvents.where((e) {
                  final isSameDate = _selectedDay == null
                      ? true
                      : (e.date.year == _selectedDay!.year &&
                            e.date.month == _selectedDay!.month &&
                            e.date.day == _selectedDay!.day);
                  final typeMatch = _filterType == 'all'
                      ? true
                      : (e.type == _filterType);
                  return isSameDate && typeMatch;
                }).toList();

                if (filteredEvents.isEmpty) {
                  return const Center(child: Text('일정이 없습니다.'));
                }

                return ListView.builder(
                  itemCount: filteredEvents.length,
                  itemBuilder: (context, index) {
                    final event = filteredEvents[index];
                    return EventCard(
                      event: event,
                      onAttend: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('${event.location} 참석!')),
                        );
                      },
                      onAbsent: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('${event.location} 불참!')),
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
