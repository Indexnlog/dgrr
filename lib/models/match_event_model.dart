import 'package:cloud_firestore/cloud_firestore.dart';

class MatchEvent {
  final String id; // 문서 ID
  final String teamId; // teams 컬렉션 문서 ID
  final String teamName; // 상대팀 이름 (캐싱)
  final DateTime? date; // 경기 날짜 (Timestamp or String)
  final String? time; // 경기 시간
  final String? location; // 장소
  final String status; // scheduled / finished / canceled
  final DateTime? createdAt; // 생성 시각
  final Score score; // 경기 결과
  final List<Participant> participants; // 참가자
  final List<MatchComment> comments; // 댓글

  MatchEvent({
    required this.id,
    required this.teamId,
    required this.teamName,
    this.date,
    this.time,
    this.location,
    required this.status,
    this.createdAt,
    required this.score,
    required this.participants,
    required this.comments,
  });

  /// Firestore → MatchEvent
  factory MatchEvent.fromMap(Map<String, dynamic> map, String id) {
    // date 변환
    DateTime? parsedDate;
    final rawDate = map['date'];
    if (rawDate is Timestamp) {
      parsedDate = rawDate.toDate();
    } else if (rawDate is String) {
      parsedDate = DateTime.tryParse(rawDate);
    }

    // createdAt 변환
    DateTime? parsedCreated;
    final rawCreated = map['createdAt'];
    if (rawCreated is Timestamp) {
      parsedCreated = rawCreated.toDate();
    } else if (rawCreated is String) {
      parsedCreated = DateTime.tryParse(rawCreated);
    }

    // participants
    final participantsList = (map['participants'] as List<dynamic>? ?? [])
        .whereType<Map<String, dynamic>>()
        .map((p) => Participant.fromMap(p))
        .toList();

    // comments
    final commentsList = (map['comments'] as List<dynamic>? ?? [])
        .whereType<Map<String, dynamic>>()
        .map((c) => MatchComment.fromMap(c))
        .toList();

    // score
    final scoreMap = map['score'] as Map<String, dynamic>? ?? {};
    final score = Score.fromMap(scoreMap);

    return MatchEvent(
      id: id,
      teamId: map['teamId']?.toString() ?? '',
      teamName: map['teamName']?.toString() ?? '',
      date: parsedDate,
      time: map['time']?.toString(),
      location: map['location']?.toString(),
      status: map['status']?.toString() ?? '',
      createdAt: parsedCreated,
      score: score,
      participants: participantsList,
      comments: commentsList,
    );
  }

  /// MatchEvent → Firestore
  Map<String, dynamic> toMap() {
    return {
      'teamId': teamId,
      'teamName': teamName,
      'date': date, // Timestamp로 자동 변환
      'time': time,
      'location': location,
      'status': status,
      'createdAt': createdAt,
      'score': score.toMap(),
      'participants': participants.map((p) => p.toMap()).toList(),
      'comments': comments.map((c) => c.toMap()).toList(),
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
