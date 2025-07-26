import 'package:cloud_firestore/cloud_firestore.dart';

/// 🗓️ 일정(수업/MT/회식) 모델
class ScheduleEvent {
  final String id; // Firestore 문서 ID
  final DateTime date; // 날짜
  final String? time; // 시간
  final String? location; // 장소
  final String? type; // lesson, mt, dinner
  final String? status; // active, confirmed 등
  final List<Attendee> attendees; // 참석자 리스트
  final List<Comment> comments; // 댓글 리스트

  ScheduleEvent({
    required this.id,
    required this.date,
    this.time,
    this.location,
    this.type,
    this.status,
    required this.attendees,
    required this.comments,
  });

  /// ✅ Firestore → ScheduleEvent
  factory ScheduleEvent.fromMap(Map<String, dynamic> map, String id) {
    // ✅ date 필드 타입 체크
    DateTime parsedDate;
    final rawDate = map['date'];
    if (rawDate is Timestamp) {
      parsedDate = rawDate.toDate();
    } else if (rawDate is String) {
      parsedDate = DateTime.tryParse(rawDate) ?? DateTime.now();
    } else {
      parsedDate = DateTime.now();
    }

    // ✅ attendees 배열 변환
    final attendeesList = (map['attendees'] as List<dynamic>? ?? [])
        .whereType<Map<String, dynamic>>()
        .map((a) => Attendee.fromMap(a))
        .toList();

    // ✅ comments 배열 변환
    final commentsList = (map['comments'] as List<dynamic>? ?? [])
        .whereType<Map<String, dynamic>>()
        .map((c) => Comment.fromMap(c))
        .toList();

    return ScheduleEvent(
      id: id,
      date: parsedDate,
      time: map['time']?.toString(),
      location: map['location']?.toString(),
      type: map['type']?.toString(),
      status: map['status']?.toString(),
      attendees: attendeesList,
      comments: commentsList,
    );
  }

  /// ✅ ScheduleEvent → Firestore
  Map<String, dynamic> toMap() {
    return {
      'date': date, // DateTime → Firestore에서 Timestamp로 자동 변환
      'time': time,
      'location': location,
      'type': type,
      'status': status,
      'attendees': attendees.map((a) => a.toMap()).toList(),
      'comments': comments.map((c) => c.toMap()).toList(),
    };
  }
}

/// 👤 참석자
class Attendee {
  final String userId;
  final String status; // attending / absent / pending
  final DateTime? updatedAt;
  final String? reason;

  Attendee({
    required this.userId,
    required this.status,
    this.updatedAt,
    this.reason,
  });

  factory Attendee.fromMap(Map<String, dynamic> map) {
    DateTime? parsedUpdated;
    final rawUpdated = map['updatedAt'];
    if (rawUpdated is Timestamp) {
      parsedUpdated = rawUpdated.toDate();
    } else if (rawUpdated is String) {
      parsedUpdated = DateTime.tryParse(rawUpdated);
    }

    return Attendee(
      userId: map['userId']?.toString() ?? '',
      status: map['status']?.toString() ?? '',
      updatedAt: parsedUpdated,
      reason: map['reason']?.toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'status': status,
      'updatedAt': updatedAt,
      'reason': reason,
    };
  }
}

/// 💬 댓글
class Comment {
  final String text;
  final String userId;

  Comment({required this.text, required this.userId});

  factory Comment.fromMap(Map<String, dynamic> map) {
    return Comment(
      text: map['text']?.toString() ?? '',
      userId: map['userId']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {'text': text, 'userId': userId};
  }
}
