import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:table_calendar/table_calendar.dart';

class SchedulePage extends StatefulWidget {
  const SchedulePage({super.key});

  @override
  State<SchedulePage> createState() => _SchedulePageState();
}

class _SchedulePageState extends State<SchedulePage> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  String get _uid => FirebaseAuth.instance.currentUser!.uid;

  Map<DateTime, List<Map<String, dynamic>>> _groupEvents(
    QuerySnapshot classSnap,
    QuerySnapshot matchSnap,
  ) {
    final Map<DateTime, List<Map<String, dynamic>>> events = {};

    for (var doc in classSnap.docs) {
      final data = doc.data() as Map<String, dynamic>;
      final Timestamp? dateTs = data['date'] as Timestamp?;
      if (dateTs != null && data['status'] == 'active') {
        final date = dateTs.toDate();
        final dayKey = DateTime(date.year, date.month, date.day);
        events.putIfAbsent(dayKey, () => []);
        events[dayKey]!.add({
          'id': doc.id,
          'type': 'class',
          'time': '${data['startTime'] ?? ''}~${data['endTime'] ?? ''}',
          'location': data['location'] ?? '',
          'teamName': '',
          'registerStart': (data['registerStart'] as Timestamp?)?.toDate(),
          'registerEnd': (data['registerEnd'] as Timestamp?)?.toDate(),
          'eventDate': date,
        });
      }
    }

    for (var doc in matchSnap.docs) {
      final data = doc.data() as Map<String, dynamic>;
      final Timestamp? dateTs = data['date'] as Timestamp?;
      if (dateTs != null && data['recruitStatus'] == 'confirmed') {
        final date = dateTs.toDate();
        final dayKey = DateTime(date.year, date.month, date.day);
        events.putIfAbsent(dayKey, () => []);
        events[dayKey]!.add({
          'id': doc.id,
          'type': 'match',
          'time': '${data['startTime'] ?? ''}~${data['endTime'] ?? ''}',
          'location': data['location'] ?? '',
          'teamName': data['teamName'] ?? '',
          'registerStart': (data['registerStart'] as Timestamp?)?.toDate(),
          'registerEnd': (data['registerEnd'] as Timestamp?)?.toDate(),
          'eventDate': date,
        });
      }
    }

    return events;
  }

  Future<void> _setRegistration(
    String eventId,
    String type,
    bool register,
  ) async {
    final regDocId = '$eventId-$_uid';
    final regRef = FirebaseFirestore.instance
        .collection('registrations')
        .doc(regDocId);

    if (register) {
      final userDoc = await FirebaseFirestore.instance
          .collection('members')
          .doc(_uid)
          .get();
      final userData = userDoc.data() ?? {};
      final userName = userData['name'] ?? '이름없음';
      final number = userData['number']?.toString() ?? '';
      final photoUrl = userData['photoUrl'] ?? '';

      await regRef.set({
        'type': type,
        'eventId': eventId,
        'userId': _uid,
        'userName': userName,
        'number': number,
        'photoUrl': photoUrl,
        'status': 'registered',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } else {
      await regRef
          .update({
            'status': 'cancelled',
            'updatedAt': FieldValue.serverTimestamp(),
          })
          .catchError((_) async {
            await regRef.set({
              'type': type,
              'eventId': eventId,
              'userId': _uid,
              'status': 'cancelled',
              'createdAt': FieldValue.serverTimestamp(),
              'updatedAt': FieldValue.serverTimestamp(),
            });
          });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('📅 일정')),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('members')
            .doc(_uid)
            .snapshots(),
        builder: (context, userSnap) {
          if (!userSnap.hasData || !userSnap.data!.exists) {
            return const Center(child: Text('사용자 정보를 불러올 수 없습니다.'));
          }

          final userData = userSnap.data!.data()!;
          final myRole = userData['role'] ?? '';

          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('classes')
                .where('status', isEqualTo: 'active')
                .snapshots(),
            builder: (context, classSnap) {
              return StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('matches')
                    .where('recruitStatus', isEqualTo: 'confirmed')
                    .snapshots(),
                builder: (context, matchSnap) {
                  final events = _groupEvents(classSnap.data!, matchSnap.data!);

                  return StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('registrations')
                        .where('userId', isEqualTo: _uid)
                        .snapshots(),
                    builder: (context, regSnap) {
                      final myRegs =
                          regSnap.data?.docs
                              .map((d) => d.data() as Map<String, dynamic>)
                              .toList() ??
                          [];

                      List<Map<String, dynamic>> getEventsForDay(DateTime day) {
                        final key = DateTime(day.year, day.month, day.day);
                        return events[key] ?? [];
                      }

                      return Column(
                        children: [
                          TableCalendar(
                            locale: 'ko_KR',
                            firstDay: DateTime.utc(2020, 1, 1),
                            lastDay: DateTime.utc(2030, 12, 31),
                            focusedDay: _focusedDay,
                            selectedDayPredicate: (day) =>
                                isSameDay(_selectedDay, day),
                            onDaySelected: (selectedDay, focusedDay) {
                              setState(() {
                                _selectedDay = selectedDay;
                                _focusedDay = focusedDay;
                              });
                            },
                            eventLoader: getEventsForDay,
                            calendarBuilders: CalendarBuilders(
                              markerBuilder: (context, date, eventsForDay) {
                                if (eventsForDay.isEmpty)
                                  return const SizedBox();
                                return Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: eventsForDay.map((e) {
                                    final event = e as Map<String, dynamic>;
                                    final color = event['type'] == 'class'
                                        ? Colors.blue
                                        : Colors.green;
                                    return Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 1,
                                      ),
                                      child: Icon(
                                        Icons.circle,
                                        size: 8,
                                        color: color,
                                      ),
                                    );
                                  }).toList(),
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 8),
                          Expanded(
                            child: ListView(
                              children: getEventsForDay(_selectedDay ?? _focusedDay).map((
                                e,
                              ) {
                                final type = e['type'];
                                final isAttending = myRegs.any(
                                  (r) =>
                                      r['eventId'] == e['id'] &&
                                      r['type'] == type &&
                                      r['status'] == 'registered',
                                );

                                final now = DateTime.now();
                                final regStart =
                                    e['registerStart'] as DateTime?;
                                final regEnd = e['registerEnd'] as DateTime?;
                                final eventDate = e['eventDate'] as DateTime?;

                                final isRegisterPeriod =
                                    regStart != null &&
                                    regEnd != null &&
                                    now.isAfter(regStart) &&
                                    now.isBefore(regEnd);

                                final canCancelUntilDayBefore =
                                    eventDate != null &&
                                    now.isBefore(
                                      DateTime(
                                            eventDate.year,
                                            eventDate.month,
                                            eventDate.day,
                                          )
                                          .subtract(const Duration(days: 1))
                                          .add(
                                            const Duration(
                                              hours: 23,
                                              minutes: 59,
                                            ),
                                          ),
                                    );

                                return Card(
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 4,
                                  ),
                                  child: ListTile(
                                    title: Text(
                                      type == 'class'
                                          ? '수업 (${e['time']})'
                                          : '매치 (${e['time']})',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    subtitle: Text(
                                      type == 'class'
                                          ? '장소: ${e['location']}'
                                          : '장소: ${e['location']} / 상대: ${e['teamName']}',
                                    ),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: Icon(
                                            Icons.check_circle,
                                            color: isAttending
                                                ? Colors.green
                                                : Colors.grey,
                                          ),
                                          onPressed: isRegisterPeriod
                                              ? () => _setRegistration(
                                                  e['id'],
                                                  type,
                                                  true,
                                                )
                                              : null,
                                        ),
                                        IconButton(
                                          icon: Icon(
                                            Icons.cancel,
                                            color: !isAttending
                                                ? Colors.red
                                                : Colors.grey,
                                          ),
                                          onPressed:
                                              (isRegisterPeriod ||
                                                  canCancelUntilDayBefore)
                                              ? () => _setRegistration(
                                                  e['id'],
                                                  type,
                                                  false,
                                                )
                                              : null,
                                        ),
                                        if (myRole == 'manager')
                                          PopupMenuButton<String>(
                                            onSelected: (value) async {
                                              if (value == 'edit') {
                                                Navigator.pushNamed(
                                                  context,
                                                  '/classAdd',
                                                  arguments: e['id'],
                                                );
                                              } else if (value == 'cancel') {
                                                final confirm =
                                                    await showDialog<bool>(
                                                      context: context,
                                                      builder: (ctx) => AlertDialog(
                                                        title: const Text(
                                                          '취소 확인',
                                                        ),
                                                        content: const Text(
                                                          '이 일정을 취소하시겠습니까?',
                                                        ),
                                                        actions: [
                                                          TextButton(
                                                            onPressed: () =>
                                                                Navigator.pop(
                                                                  ctx,
                                                                  false,
                                                                ),
                                                            child: const Text(
                                                              '아니요',
                                                            ),
                                                          ),
                                                          ElevatedButton(
                                                            onPressed: () =>
                                                                Navigator.pop(
                                                                  ctx,
                                                                  true,
                                                                ),
                                                            child: const Text(
                                                              '취소하기',
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    );
                                                if (confirm == true) {
                                                  await FirebaseFirestore
                                                      .instance
                                                      .collection(
                                                        type == 'class'
                                                            ? 'classes'
                                                            : 'matches',
                                                      )
                                                      .doc(e['id'])
                                                      .update({
                                                        'status': 'canceled',
                                                      });
                                                }
                                              }
                                            },
                                            itemBuilder: (c) => const [
                                              PopupMenuItem(
                                                value: 'edit',
                                                child: Text('✏️ 수정'),
                                              ),
                                              PopupMenuItem(
                                                value: 'cancel',
                                                child: Text('🚫 취소'),
                                              ),
                                            ],
                                          ),
                                      ],
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ],
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
