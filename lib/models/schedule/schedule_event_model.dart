import 'package:cloud_firestore/cloud_firestore.dart';

class ScheduleEvent {
  final String id;
  final String teamId;
  final String type; // 'class', 'match', 'event'
  final String title;
  final String? date; // YYYY-MM-DD
  final String? time; // HH:mm
  final String? location;
  final List<dynamic> attendees; // 클래스/매치 구조 다르므로 dynamic 처리
  final Timestamp? createdAt;

  ScheduleEvent({
    required this.id,
    required this.teamId,
    required this.type,
    required this.title,
    this.date,
    this.time,
    this.location,
    required this.attendees,
    this.createdAt,
  });
}
