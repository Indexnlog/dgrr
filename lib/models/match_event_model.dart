import 'package:cloud_firestore/cloud_firestore.dart';

class MatchEvent {
  final String id;
  final String teamId;
  final String teamName;
  final DateTime date;
  final String? time;
  final String? location;
  final dynamic score;

  // 🔥 새로 추가
  final String recruitStatus; // waiting / confirmed
  final String gameStatus; // notStarted / inProgress / finished

  MatchEvent({
    required this.id,
    required this.teamId,
    required this.teamName,
    required this.date,
    this.time,
    this.location,
    this.score,
    this.recruitStatus = 'waiting',
    this.gameStatus = 'notStarted',
  });

  factory MatchEvent.fromMap(Map<String, dynamic> data, String documentId) {
    return MatchEvent(
      id: documentId,
      teamId: data['teamId'] ?? '',
      teamName: data['teamName'] ?? '',
      date: (data['date'] as Timestamp).toDate(),
      time: data['time'],
      location: data['location'],
      score: data['score'],
      recruitStatus: data['recruitStatus'] ?? 'waiting',
      gameStatus: data['gameStatus'] ?? 'notStarted',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'teamId': teamId,
      'teamName': teamName,
      'date': date,
      'time': time,
      'location': location,
      'score': score,
      'recruitStatus': recruitStatus,
      'gameStatus': gameStatus,
    };
  }
}

/// 🏷️ 점수
class Score {
  final int home;
  final int away;

  Score({required this.home, required this.away});

  factory Score.fromMap(Map<String, dynamic> map) {
    return Score(
      home: map['home'] is int ? map['home'] : (map['home'] ?? 0),
      away: map['away'] is int ? map['away'] : (map['away'] ?? 0),
    );
  }

  Map<String, dynamic> toMap() {
    return {'home': home, 'away': away};
  }
}

/// 👤 참가자
class Participant {
  final String userId;
  final String status; // attending / absent / pending
  final DateTime? updatedAt;
  final String? reason;

  Participant({
    required this.userId,
    required this.status,
    this.updatedAt,
    this.reason,
  });

  factory Participant.fromMap(Map<String, dynamic> map) {
    DateTime? parsedUpdated;
    final rawUpdated = map['updatedAt'];
    if (rawUpdated is Timestamp) {
      parsedUpdated = rawUpdated.toDate();
    } else if (rawUpdated is String) {
      parsedUpdated = DateTime.tryParse(rawUpdated);
    }

    return Participant(
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

/// 💬 경기 댓글
class MatchComment {
  final String text;
  final String userId;

  MatchComment({required this.text, required this.userId});

  factory MatchComment.fromMap(Map<String, dynamic> map) {
    return MatchComment(
      text: map['text']?.toString() ?? '',
      userId: map['userId']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {'text': text, 'userId': userId};
  }
}
