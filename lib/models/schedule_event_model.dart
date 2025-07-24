class ScheduleEvent {
  final String id;
  final DateTime date;
  final String time;
  final String location;
  final String type; // lesson, match, mt, dinner
  final List<Attendee> attendees;
  final String status;

  ScheduleEvent({
    required this.id,
    required this.date,
    required this.time,
    required this.location,
    required this.type,
    required this.attendees,
    required this.status,
  });

  factory ScheduleEvent.fromMap(Map<String, dynamic> map, String id) {
    return ScheduleEvent(
      id: id,
      date: DateTime.parse(map['date']),
      time: map['time'] ?? '',
      location: map['location'] ?? '',
      type: map['type'] ?? 'lesson',
      attendees: (map['attendees'] as List<dynamic>? ?? [])
          .map((a) => Attendee.fromMap(a))
          .toList(),
      status: map['status'] ?? 'active',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'date': date.toIso8601String(),
      'time': time,
      'location': location,
      'type': type,
      'attendees': attendees.map((a) => a.toMap()).toList(),
      'status': status,
    };
  }
}

class Attendee {
  final String userId;
  final String status; // attending / absent
  final DateTime updatedAt;
  final String? reason;

  Attendee({
    required this.userId,
    required this.status,
    required this.updatedAt,
    this.reason,
  });

  factory Attendee.fromMap(Map<String, dynamic> map) {
    return Attendee(
      userId: map['userId'],
      status: map['status'],
      updatedAt: DateTime.parse(map['updatedAt']),
      reason: map['reason'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'status': status,
      'updatedAt': updatedAt.toIso8601String(),
      'reason': reason,
    };
  }
}
