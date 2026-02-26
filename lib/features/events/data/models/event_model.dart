import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/event.dart';

/// 이벤트 모델 (Firestore 변환 포함)
class EventModel extends Event {
  const EventModel({
    required super.eventId,
    required super.type,
    super.title,
    super.description,
    super.date,
    super.startTime,
    super.endTime,
    super.location,
    super.status,
    super.registerStart,
    super.registerEnd,
    super.fromPoll,
    super.pollId,
    super.createdBy,
    super.createdAt,
    super.updatedAt,
    super.attendance,
    super.attendees,
    super.comments,
    super.eventType,
  });

  factory EventModel.fromFirestore(String id, Map<String, dynamic> json) {
    return EventModel(
      eventId: id,
      type: EventType.fromString(json['type'] as String?) ?? EventType.social,
      title: json['title'] as String?,
      description: json['description'] as String?,
      date: json['date'] as String?,
      startTime: json['startTime'] as String?,
      endTime: json['endTime'] as String?,
      location: json['location'] as String?,
      status: EventStatus.fromString(json['status'] as String?),
      registerStart: (json['registerStart'] as Timestamp?)?.toDate(),
      registerEnd: (json['registerEnd'] as Timestamp?)?.toDate(),
      fromPoll: json['fromPoll'] as bool?,
      pollId: json['pollId'] as String?,
      createdBy: json['createdBy'] as String?,
      createdAt: (json['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (json['updatedAt'] as Timestamp?)?.toDate(),
      // 수업 전용 필드
      attendance: json['attendance'] != null
          ? AttendanceSummaryModel.fromMap(
              json['attendance'] as Map<String, dynamic>)
          : null,
      attendees: json['attendees'] != null
          ? (json['attendees'] as List)
              .map((e) => EventAttendeeModel.fromMap(e as Map<String, dynamic>))
              .toList()
          : null,
      comments: json['comments'] != null
          ? (json['comments'] as List)
              .map((e) => EventCommentModel.fromMap(e as Map<String, dynamic>))
              .toList()
          : null,
      // 이벤트 전용 필드
      eventType: json['eventType'] as String?,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'type': type.value,
      if (title != null) 'title': title,
      if (description != null) 'description': description,
      if (date != null) 'date': date,
      if (startTime != null) 'startTime': startTime,
      if (endTime != null) 'endTime': endTime,
      if (location != null) 'location': location,
      if (status != null) 'status': status!.value,
      if (registerStart != null)
        'registerStart': Timestamp.fromDate(registerStart!),
      if (registerEnd != null)
        'registerEnd': Timestamp.fromDate(registerEnd!),
      if (fromPoll != null) 'fromPoll': fromPoll,
      if (pollId != null) 'pollId': pollId,
      if (createdBy != null) 'createdBy': createdBy,
      if (createdAt != null) 'createdAt': Timestamp.fromDate(createdAt!),
      if (updatedAt != null) 'updatedAt': Timestamp.fromDate(updatedAt!),
      // 수업 전용 필드
      if (attendance != null)
        'attendance': AttendanceSummaryModel.toMap(attendance!),
      if (attendees != null)
        'attendees': attendees!.map((e) => EventAttendeeModel.toMap(e)).toList(),
      if (comments != null)
        'comments': comments!.map((e) => EventCommentModel.toMap(e)).toList(),
      // 이벤트 전용 필드
      if (eventType != null) 'eventType': eventType,
    };
  }

  @override
  EventModel copyWith({
    String? eventId,
    EventType? type,
    String? title,
    String? description,
    String? date,
    String? startTime,
    String? endTime,
    String? location,
    EventStatus? status,
    DateTime? registerStart,
    DateTime? registerEnd,
    bool? fromPoll,
    String? pollId,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
    AttendanceSummary? attendance,
    List<EventAttendee>? attendees,
    List<EventComment>? comments,
    String? eventType,
  }) {
    return EventModel(
      eventId: eventId ?? this.eventId,
      type: type ?? this.type,
      title: title ?? this.title,
      description: description ?? this.description,
      date: date ?? this.date,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      location: location ?? this.location,
      status: status ?? this.status,
      registerStart: registerStart ?? this.registerStart,
      registerEnd: registerEnd ?? this.registerEnd,
      fromPoll: fromPoll ?? this.fromPoll,
      pollId: pollId ?? this.pollId,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      attendance: attendance ?? this.attendance,
      attendees: attendees ?? this.attendees,
      comments: comments ?? this.comments,
      eventType: eventType ?? this.eventType,
    );
  }
}

/// 출석 요약 모델
class AttendanceSummaryModel extends AttendanceSummary {
  const AttendanceSummaryModel({
    super.present,
    super.absent,
  });

  factory AttendanceSummaryModel.fromMap(Map<String, dynamic> json) {
    return AttendanceSummaryModel(
      present: json['present'] as int?,
      absent: json['absent'] as int?,
    );
  }

  static Map<String, dynamic> toMap(AttendanceSummary summary) {
    return {
      if (summary.present != null) 'present': summary.present,
      if (summary.absent != null) 'absent': summary.absent,
    };
  }
}

/// 이벤트 참석자 모델
class EventAttendeeModel extends EventAttendee {
  const EventAttendeeModel({
    required super.userId,
    super.userName,
    super.number,
    super.status,
    super.reason,
    super.updatedAt,
  });

  factory EventAttendeeModel.fromMap(Map<String, dynamic> json) {
    return EventAttendeeModel(
      userId: json['userId'] as String? ?? '',
      userName: json['userName'] as String?,
      number: json['number'] as int?,
      status: AttendeeStatus.fromString(json['status'] as String?),
      reason: json['reason'] as String?,
      updatedAt: (json['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  static Map<String, dynamic> toMap(EventAttendee attendee) {
    return {
      'userId': attendee.userId,
      if (attendee.userName != null) 'userName': attendee.userName,
      if (attendee.number != null) 'number': attendee.number,
      if (attendee.status != null) 'status': attendee.status!.value,
      if (attendee.reason != null) 'reason': attendee.reason,
      if (attendee.updatedAt != null)
        'updatedAt': Timestamp.fromDate(attendee.updatedAt!),
    };
  }
}

/// 이벤트 댓글 모델
class EventCommentModel extends EventComment {
  const EventCommentModel({
    required super.userId,
    super.text,
  });

  factory EventCommentModel.fromMap(Map<String, dynamic> json) {
    return EventCommentModel(
      userId: json['userId'] as String? ?? '',
      text: json['text'] as String?,
    );
  }

  static Map<String, dynamic> toMap(EventComment comment) {
    return {
      'userId': comment.userId,
      if (comment.text != null) 'text': comment.text,
    };
  }
}
