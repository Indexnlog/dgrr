import 'package:cloud_firestore/cloud_firestore.dart';

/// 경기 또는 수업 이벤트 타입
enum EventType { lesson, match, unknown }

EventType eventTypeFromString(String value) {
  switch (value.toLowerCase()) {
    case 'lesson':
      return EventType.lesson;
    case 'match':
      return EventType.match;
    default:
      return EventType.unknown;
  }
}

String eventTypeToString(EventType type) {
  switch (type) {
    case EventType.lesson:
      return 'lesson';
    case EventType.match:
      return 'match';
    default:
      return 'unknown';
  }
}

class MatchEventModel {
  final String id;
  final String teamId;
  final String title;
  final String description;
  final EventType eventType;
  final String date;
  final String startTime;
  final String endTime;
  final String? location;
  final bool fromPoll;
  final String pollId;
  final String status; // confirmed, cancelled, pending
  final String createdBy;
  final Timestamp createdAt;
  final Timestamp updatedAt;
  final List<Attendee> attendees;
  final List<Comment> comments;

  MatchEventModel({
    required this.id,
    required this.teamId,
    required this.title,
    required this.description,
    required this.eventType,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.location,
    required this.fromPoll,
    required this.pollId,
    required this.status,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
    required this.attendees,
    required this.comments,
  });

  factory MatchEventModel.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    return MatchEventModel(
      id: doc.id,
      teamId: data['teamId'] ?? '',
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      eventType: eventTypeFromString(data['eventType'] ?? ''),
      date: data['date'] ?? '',
      startTime: data['startTime'] ?? '',
      endTime: data['endTime'] ?? '',
      location: data['location'],
      fromPoll: data['fromPoll'] ?? false,
      pollId: data['pollId'] ?? '',
      status: data['status'] ?? 'pending',
      createdBy: data['createdBy'] ?? '',
      createdAt: data['createdAt'] ?? Timestamp.now(),
      updatedAt: data['updatedAt'] ?? Timestamp.now(),
      attendees: (data['attendees'] as List<dynamic>? ?? [])
          .map((e) => Attendee.fromMap(e as Map<String, dynamic>))
          .toList(),
      comments: (data['comments'] as List<dynamic>? ?? [])
          .map((e) => Comment.fromMap(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'teamId': teamId,
      'title': title,
      'description': description,
      'eventType': eventTypeToString(eventType),
      'date': date,
      'startTime': startTime,
      'endTime': endTime,
      'location': location,
      'fromPoll': fromPoll,
      'pollId': pollId,
      'status': status,
      'createdBy': createdBy,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'attendees': attendees.map((e) => e.toMap()).toList(),
      'comments': comments.map((e) => e.toMap()).toList(),
    };
  }

  MatchEventModel copyWith({
    String? title,
    String? status,
    List<Comment>? comments,
    List<Attendee>? attendees,
  }) {
    return MatchEventModel(
      id: id,
      teamId: teamId,
      title: title ?? this.title,
      description: description,
      eventType: eventType,
      date: date,
      startTime: startTime,
      endTime: endTime,
      location: location,
      fromPoll: fromPoll,
      pollId: pollId,
      status: status ?? this.status,
      createdBy: createdBy,
      createdAt: createdAt,
      updatedAt: updatedAt,
      attendees: attendees ?? this.attendees,
      comments: comments ?? this.comments,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is MatchEventModel &&
        other.id == id &&
        other.teamId == teamId &&
        other.title == title &&
        other.date == date;
  }

  @override
  int get hashCode =>
      id.hashCode ^ teamId.hashCode ^ title.hashCode ^ date.hashCode;
}

/// 출석자 정보
class Attendee {
  final String userId;
  final String userName;
  final int number; // 등번호

  Attendee({
    required this.userId,
    required this.userName,
    required this.number,
  });

  factory Attendee.fromMap(Map<String, dynamic> map) {
    return Attendee(
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? '',
      number: map['number'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {'userId': userId, 'userName': userName, 'number': number};
  }
}

/// 댓글 정보
class Comment {
  final String userId;
  final String userName;
  final String text;
  final Timestamp createdAt;

  Comment({
    required this.userId,
    required this.userName,
    required this.text,
    required this.createdAt,
  });

  factory Comment.fromMap(Map<String, dynamic> map) {
    return Comment(
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? '',
      text: map['text'] ?? '',
      createdAt: map['createdAt'] ?? Timestamp.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userName': userName,
      'text': text,
      'createdAt': createdAt,
    };
  }
}
