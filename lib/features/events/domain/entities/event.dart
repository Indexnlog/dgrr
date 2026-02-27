/// 이벤트 엔티티 (수업, 모임 등)
class Event {
  const Event({
    required this.eventId,
    required this.type,
    this.title,
    this.description,
    this.date,
    this.startTime,
    this.endTime,
    this.location,
    this.status,
    this.registerStart,
    this.registerEnd,
    this.fromPoll,
    this.pollId,
    this.createdBy,
    this.createdAt,
    this.updatedAt,
    // 수업 전용 필드
    this.attendance,
    this.attendees,
    this.comments,
    // 이벤트 전용 필드
    this.eventType,
  });

  final String eventId;
  final EventType type;
  final String? title;
  final String? description;
  final String? date;
  final String? startTime;
  final String? endTime;
  final String? location;
  final EventStatus? status;
  final DateTime? registerStart;
  final DateTime? registerEnd;
  final bool? fromPoll;
  final String? pollId;
  final String? createdBy;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  // 수업 전용 필드 (type == 'class')
  final AttendanceSummary? attendance;
  final List<EventAttendee>? attendees;
  final List<EventComment>? comments;

  // 이벤트 전용 필드 (type == 'social')
  final String? eventType;

  Event copyWith({
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
    return Event(
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

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Event && other.eventId == eventId;
  }

  @override
  int get hashCode => eventId.hashCode;
}

enum EventType {
  class_,
  social,
  tournament;

  String get value {
    switch (this) {
      case EventType.class_:
        return 'class';
      case EventType.social:
        return 'social';
      case EventType.tournament:
        return 'tournament';
    }
  }

  static EventType? fromString(String? value) {
    if (value == null) return null;
    switch (value) {
      case 'class':
        return EventType.class_;
      case 'social':
        return EventType.social;
      case 'tournament':
        return EventType.tournament;
      default:
        return null;
    }
  }
}

enum EventStatus {
  active,
  confirmed,
  finished,
  cancelled;

  String get value {
    switch (this) {
      case EventStatus.active:
        return 'active';
      case EventStatus.confirmed:
        return 'confirmed';
      case EventStatus.finished:
        return 'finished';
      case EventStatus.cancelled:
        return 'cancelled';
    }
  }

  static EventStatus? fromString(String? value) {
    if (value == null) return null;
    switch (value) {
      case 'active':
        return EventStatus.active;
      case 'confirmed':
        return EventStatus.confirmed;
      case 'finished':
        return EventStatus.finished;
      case 'cancelled':
        return EventStatus.cancelled;
      default:
        return null;
    }
  }
}

/// 출석 요약 정보
class AttendanceSummary {
  const AttendanceSummary({
    this.present,
    this.absent,
  });

  final int? present;
  final int? absent;

  AttendanceSummary copyWith({
    int? present,
    int? absent,
  }) {
    return AttendanceSummary(
      present: present ?? this.present,
      absent: absent ?? this.absent,
    );
  }
}

/// 이벤트 참석자 정보
class EventAttendee {
  const EventAttendee({
    required this.userId,
    this.userName,
    this.number,
    this.status,
    this.reason,
    this.updatedAt,
  });

  final String userId;
  final String? userName;
  final int? number;
  final AttendeeStatus? status;
  final String? reason;
  final DateTime? updatedAt;

  EventAttendee copyWith({
    String? userId,
    String? userName,
    int? number,
    AttendeeStatus? status,
    String? reason,
    DateTime? updatedAt,
  }) {
    return EventAttendee(
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      number: number ?? this.number,
      status: status ?? this.status,
      reason: reason ?? this.reason,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

enum AttendeeStatus {
  attending,
  late,
  absent,
  /// 이벤트 종료 후 참석 확정 (attending/late → attended 자동 전환)
  attended;

  String get value {
    switch (this) {
      case AttendeeStatus.attending:
        return 'attending';
      case AttendeeStatus.late:
        return 'late';
      case AttendeeStatus.absent:
        return 'absent';
      case AttendeeStatus.attended:
        return 'attended';
    }
  }

  static AttendeeStatus? fromString(String? value) {
    if (value == null) return null;
    switch (value) {
      case 'attending':
        return AttendeeStatus.attending;
      case 'late':
        return AttendeeStatus.late;
      case 'absent':
        return AttendeeStatus.absent;
      case 'attended':
        return AttendeeStatus.attended;
      default:
        return null;
    }
  }
}

/// 이벤트 댓글
class EventComment {
  const EventComment({
    required this.userId,
    this.text,
  });

  final String userId;
  final String? text;

  EventComment copyWith({
    String? userId,
    String? text,
  }) {
    return EventComment(
      userId: userId ?? this.userId,
      text: text ?? this.text,
    );
  }
}
