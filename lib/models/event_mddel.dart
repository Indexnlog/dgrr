import 'package:cloud_firestore/cloud_firestore.dart';

class EventModel {
  final String id;
  final String teamId; // ✅ 추가됨
  final String title;
  final String description;
  final String eventType;
  final String date; // YYYY-MM-DD
  final String startTime; // HH:mm
  final String endTime; // HH:mm
  final String location;
  final bool fromPoll;
  final String pollId;
  final String status; // confirmed, cancelled, pending
  final String createdBy;
  final Timestamp createdAt;
  final Timestamp updatedAt;
  final List<Attendee> attendees;
  final List<Comment> comments;

  EventModel({
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

  factory EventModel.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return EventModel(
      id: doc.id,
      teamId: data['teamId'] ?? '',
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      eventType: data['eventType'] ?? '',
      date: data['date'] ?? '',
      startTime: data['startTime'] ?? '',
      endTime: data['endTime'] ?? '',
      location: data['location'] ?? '',
      fromPoll: data['fromPoll'] ?? false,
      pollId: data['pollId'] ?? '',
      status: data['status'] ?? 'pending',
      createdBy: data['createdBy'] ?? '',
      createdAt: data['createdAt'] ?? Timestamp.now(),
      updatedAt: data['updatedAt'] ?? Timestamp.now(),
      attendees: (data['attendees'] as List<dynamic>? ?? [])
          .map((e) => Attendee.fromMap(e))
          .toList(),
      comments: (data['comments'] as List<dynamic>? ?? [])
          .map((e) => Comment.fromMap(e))
          .toList(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'teamId': teamId,
      'title': title,
      'description': description,
      'eventType': eventType,
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
}

class Attendee {
  final String userId;
  final String userName;
  final int number;

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

class Comment {
  final String userId;
  final String text;
  final Timestamp createdAt;

  Comment({required this.userId, required this.text, required this.createdAt});

  factory Comment.fromMap(Map<String, dynamic> map) {
    return Comment(
      userId: map['userId'] ?? '',
      text: map['text'] ?? '',
      createdAt: map['createdAt'] ?? Timestamp.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {'userId': userId, 'text': text, 'createdAt': createdAt};
  }
}
