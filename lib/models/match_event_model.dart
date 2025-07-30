import 'package:cloud_firestore/cloud_firestore.dart';

/// 📌 매치 기본 정보 (전체 메타)
class MatchEvent {
  final String id;
  final String teamId;
  final String teamName;
  final DateTime date;
  final String? startTime; // ✅ 추가
  final String? endTime; // ✅ 추가
  final String? location;
  final String recruitStatus;
  final String gameStatus;

  MatchEvent({
    required this.id,
    required this.teamId,
    required this.teamName,
    required this.date,
    this.startTime, // ✅ 추가
    this.endTime, // ✅ 추가
    this.location,
    this.recruitStatus = 'waiting',
    this.gameStatus = 'notStarted',
  });

  factory MatchEvent.fromMap(Map<String, dynamic> data, String documentId) {
    return MatchEvent(
      id: documentId,
      teamId: data['teamId'] ?? '',
      teamName: data['teamName'] ?? '',
      date: (data['date'] as Timestamp).toDate(),
      startTime: data['startTime'], // ✅ 추가
      endTime: data['endTime'], // ✅ 추가
      location: data['location'],
      recruitStatus: data['recruitStatus'] ?? 'waiting',
      gameStatus: data['gameStatus'] ?? 'notStarted',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'teamId': teamId,
      'teamName': teamName,
      'date': date,
      'startTime': startTime, // ✅ 추가
      'endTime': endTime, // ✅ 추가
      'location': location,
      'recruitStatus': recruitStatus,
      'gameStatus': gameStatus,
    };
  }
}

/// 📌 라운드 정보 (하위 컬렉션)
class Round {
  final String id; // r1, r2, r3...
  final String status; // notStarted / inProgress / finished
  final DateTime? startTime;
  final DateTime? endTime;
  final int homeScore;
  final int awayScore;

  Round({
    required this.id,
    required this.status,
    this.startTime,
    this.endTime,
    required this.homeScore,
    required this.awayScore,
  });

  factory Round.fromMap(Map<String, dynamic> data, String docId) {
    return Round(
      id: docId,
      status: data['status'] ?? 'notStarted',
      startTime: data['startTime'] != null
          ? (data['startTime'] as Timestamp).toDate()
          : null,
      endTime: data['endTime'] != null
          ? (data['endTime'] as Timestamp).toDate()
          : null,
      homeScore: data['score']?['home'] ?? 0,
      awayScore: data['score']?['away'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'status': status,
      'startTime': startTime,
      'endTime': endTime,
      'score': {'home': homeScore, 'away': awayScore},
    };
  }
}

/// 📌 라운드 안의 기록 (득점/교체)
class RoundRecord {
  final String id;
  final String type; // goal / change
  final String team; // home / away
  final int timeOffset; // 시작으로부터 몇분 뒤
  final String? playerName; // 득점한 선수
  final String? inPlayerName; // 교체 IN
  final String? outPlayerName; // 교체 OUT
  final String? memo;

  RoundRecord({
    required this.id,
    required this.type,
    required this.team,
    required this.timeOffset,
    this.playerName,
    this.inPlayerName,
    this.outPlayerName,
    this.memo,
  });

  factory RoundRecord.fromMap(Map<String, dynamic> data, String docId) {
    return RoundRecord(
      id: docId,
      type: data['type'] ?? '',
      team: data['team'] ?? '',
      timeOffset: (data['timeOffset'] is int)
          ? data['timeOffset']
          : int.tryParse(data['timeOffset'].toString()) ?? 0,
      playerName: data['playerName'],
      inPlayerName: data['inPlayerName'],
      outPlayerName: data['outPlayerName'],
      memo: data['memo'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'type': type,
      'team': team,
      'timeOffset': timeOffset,
      'playerName': playerName,
      'inPlayerName': inPlayerName,
      'outPlayerName': outPlayerName,
      'memo': memo,
    };
  }
}

/// 👤 참가자 (기존 구조 유지)
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

/// 💬 경기 댓글 (기존 구조 유지)
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
