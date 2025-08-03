import 'package:cloud_firestore/cloud_firestore.dart';

class ClassModel {
  final String id;
  final String teamId; // ✅ 추가
  final String date; // YYYY-MM-DD
  final String startTime; // HH:mm
  final String endTime; // HH:mm
  final String location;
  final Timestamp registerStart;
  final Timestamp registerEnd;
  final String status; // active, cancelled
  final String type; // lesson, training 등
  final Attendance? attendance;
  final List<Comment> comments;

  ClassModel({
    required this.id,
    required this.teamId,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.location,
    required this.registerStart,
    required this.registerEnd,
    required this.status,
    required this.type,
    required this.attendance,
    required this.comments,
  });

  factory ClassModel.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return ClassModel(
      id: doc.id,
      teamId: data['teamId'] ?? '',
      date: data['date'] ?? '',
      startTime: data['startTime'] ?? '',
      endTime: data['endTime'] ?? '',
      location: data['location'] ?? '',
      registerStart: data['registerStart'],
      registerEnd: data['registerEnd'],
      status: data['status'] ?? '',
      type: data['type'] ?? '',
      attendance: data['attendance'] != null
          ? Attendance.fromMap(data['attendance'])
          : null,
      comments: (data['comments'] as List<dynamic>? ?? [])
          .map((e) => Comment.fromMap(e))
          .toList(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'teamId': teamId,
      'date': date,
      'startTime': startTime,
      'endTime': endTime,
      'location': location,
      'registerStart': registerStart,
      'registerEnd': registerEnd,
      'status': status,
      'type': type,
      'attendance': attendance?.toMap(),
      'comments': comments.map((e) => e.toMap()).toList(),
    };
  }
}

class Attendance {
  final int absent;
  final int present;
  final List<Attendee> attendees;

  Attendance({
    required this.absent,
    required this.present,
    required this.attendees,
  });

  factory Attendance.fromMap(Map<String, dynamic> map) {
    return Attendance(
      absent: map['absent'] ?? 0,
      present: map['present'] ?? 0,
      attendees: (map['attendees'] as List<dynamic>? ?? [])
          .map((e) => Attendee.fromMap(e))
          .toList(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'absent': absent,
      'present': present,
      'attendees': attendees.map((e) => e.toMap()).toList(),
    };
  }
}

class Attendee {
  final String userId;
  final String status; // attending, absent
  final String reason;
  final Timestamp updatedAt;

  Attendee({
    required this.userId,
    required this.status,
    required this.reason,
    required this.updatedAt,
  });

  factory Attendee.fromMap(Map<String, dynamic> map) {
    return Attendee(
      userId: map['userId'] ?? '',
      status: map['status'] ?? '',
      reason: map['reason'] ?? '',
      updatedAt: map['updatedAt'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'status': status,
      'reason': reason,
      'updatedAt': updatedAt,
    };
  }
}

class Comment {
  final String userId;
  final String text;

  Comment({required this.userId, required this.text});

  factory Comment.fromMap(Map<String, dynamic> map) {
    return Comment(userId: map['userId'] ?? '', text: map['text'] ?? '');
  }

  Map<String, dynamic> toMap() {
    return {'userId': userId, 'text': text};
  }
}
