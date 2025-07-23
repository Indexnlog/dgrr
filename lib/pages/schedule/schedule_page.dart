import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:url_launcher/url_launcher.dart';

class SchedulePage extends StatefulWidget {
  const SchedulePage({Key? key}) : super(key: key);

  @override
  State<SchedulePage> createState() => _SchedulePageState();
}

class _SchedulePageState extends State<SchedulePage> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    // ✅ 앱 시작 시 오늘 날짜 선택
    _selectedDay = _focusedDay;
  }

  // 임시 이벤트 데이터 (추후 Firestore로 교체)
  final List<Map<String, dynamic>> _events = [
    {
      'date': DateTime(2025, 7, 25),
      'type': 'lesson',
      'time': '20:00~22:00',
      'location': '금천구 풋살장',
      'latlng': '37.456,126.895',
      'attend': 12,
    },
    {
      'date': DateTime(2025, 7, 28),
      'type': 'match',
      'time': '18:00~20:00',
      'location': '구로 풋살장',
      'latlng': '구로구 고척동 123-4',
      'attend': 9,
    },
  ];

  // 선택된 날짜에 해당하는 이벤트
  List<Map<String, dynamic>> get _selectedEvents {
    if (_selectedDay == null) return [];
    return _events.where((e) {
      return e['date'].year == _selectedDay!.year &&
          e['date'].month == _selectedDay!.month &&
          e['date'].day == _selectedDay!.day;
    }).toList();
  }

  // ✅ 지도 연동 (latlng 우선, 없으면 location)
  Future<void> _openMap(Map<String, dynamic> event) async {
    final query = event['latlng'] ?? event['location'];
    final encoded = Uri.encodeComponent(query);
    final googleUrl = 'https://www.google.com/maps/search/?api=1&query=$encoded';

    if (await canLaunchUrl(Uri.parse(googleUrl))) {
      await launchUrl(Uri.parse(googleUrl), mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('지도를 열 수 없습니다.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('📅 일정')),
      body: Column(
        children: [
          // ✅ 범례(legend)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.circle, color: Colors.blue, size: 10),
                SizedBox(width: 4),
                Text('수업'),
                SizedBox(width: 16),
                Icon(Icons.circle, color: Colors.green, size: 10),
                SizedBox(width: 4),
                Text('매치'),
              ],
            ),
          ),

          // 달력
          TableCalendar(
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
            },
            // ✅ 달력 스타일
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
            // ✅ 날짜 아래 점 표시
            calendarBuilders: CalendarBuilders(
              markerBuilder: (context, date, events) {
                final hasLesson = _events.any((e) =>
                    isSameDay(e['date'], date) && e['type'] == 'lesson');
                final hasMatch = _events.any((e) =>
                    isSameDay(e['date'], date) && e['type'] == 'match');
                return Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (hasLesson)
                      const Icon(Icons.circle, color: Colors.blue, size: 8),
                    if (hasMatch)
                      const Icon(Icons.circle, color: Colors.green, size: 8),
                  ],
                );
              },
            ),
          ),

          const Divider(),

          // 선택한 날짜
          if (_selectedDay != null)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                '${_selectedDay!.month}월 ${_selectedDay!.day}일 일정',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),

          // 일정 리스트
          Expanded(
            child: ListView.builder(
              itemCount: _selectedEvents.length,
              itemBuilder: (context, index) {
                final event = _selectedEvents[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: ListTile(
                    leading: Icon(
                      event['type'] == 'lesson'
                          ? Icons.school
                          : Icons.sports_soccer,
                      color: event['type'] == 'lesson'
                          ? Colors.blue
                          : Colors.green,
                    ),
                    title: Text(
                      '${event['type'] == 'lesson' ? '수업' : '매치'} ${event['time']}',
                    ),
                    subtitle: Text('@${event['location']} (${event['attend']}명 참석)'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.check_circle, color: Colors.green),
                          onPressed: () {
                            // 참석 로직(Firestore 연동 예정)
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.cancel, color: Colors.red),
                          onPressed: () {
                            // 불참 로직(Firestore 연동 예정)
                          },
                        ),
                      ],
                    ),
                    onTap: () {
                      _openMap(event); // ✅ 지도 연동
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
