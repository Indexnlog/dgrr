import 'package:cloud_firestore/cloud_firestore.dart';

class MatchModel {
  final String id;
  final String teamId;
  final String teamName;
  final Timestamp date;
  final String startTime;
  final String endTime;
  final String location;
  final List<String> participants;
  final String gameStatus;
  final String recruitStatus;
  final Timestamp registerStart;
  final Timestamp registerEnd;
  final Timestamp createdAt;
  final String createdBy;

  MatchModel({
    required this.id,
    required this.teamId,
    required this.teamName,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.location,
    required this.participants,
    required this.gameStatus,
    required this.recruitStatus,
    required this.registerStart,
    required this.registerEnd,
    required this.createdAt,
    required this.createdBy,
  });

  factory MatchModel.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return MatchModel(
      id: doc.id,
      teamId: data['teamId'] ?? '',
      teamName: data['teamName'] ?? '',
      date: data['date'] ?? Timestamp.now(),
      startTime: data['startTime'] ?? '',
      endTime: data['endTime'] ?? '',
      location: data['location'] ?? '',
      participants: List<String>.from(data['participants'] ?? []),
      gameStatus: data['gameStatus'] ?? 'notStarted',
      recruitStatus: data['recruitStatus'] ?? 'pending',
      registerStart: data['registerStart'] ?? Timestamp.now(),
      registerEnd: data['registerEnd'] ?? Timestamp.now(),
      createdAt: data['createdAt'] ?? Timestamp.now(),
      createdBy: data['createdBy'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'teamId': teamId,
      'teamName': teamName,
      'date': date,
      'startTime': startTime,
      'endTime': endTime,
      'location': location,
      'participants': participants,
      'gameStatus': gameStatus,
      'recruitStatus': recruitStatus,
      'registerStart': registerStart,
      'registerEnd': registerEnd,
      'createdAt': createdAt,
      'createdBy': createdBy,
    };
  }
}

class MatchRound {
  final String id;
  final int roundNumber;
  final Timestamp startTime;
  final Timestamp endTime;
  final Map<String, int> score;
  final String status;
  final Timestamp createdAt;

  MatchRound({
    required this.id,
    required this.roundNumber,
    required this.startTime,
    required this.endTime,
    required this.score,
    required this.status,
    required this.createdAt,
  });

  factory MatchRound.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return MatchRound(
      id: doc.id,
      roundNumber: data['roundNumber'] ?? 1,
      startTime: data['startTime'] ?? Timestamp.now(),
      endTime: data['endTime'] ?? Timestamp.now(),
      score: Map<String, int>.from(data['score'] ?? {'home': 0, 'away': 0}),
      status: data['status'] ?? 'notStarted',
      createdAt: data['createdAt'] ?? Timestamp.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'roundNumber': roundNumber,
      'startTime': startTime,
      'endTime': endTime,
      'score': score,
      'status': status,
      'createdAt': createdAt,
    };
  }
}

class MatchRecord {
  final String id;
  final String teamId;
  final String teamType;
  final String type;
  final Timestamp timestamp;
  final num timeOffset;
  final String roundId;
  final String createdBy;
  final Map<String, dynamic> data;

  MatchRecord({
    required this.id,
    required this.teamId,
    required this.teamType,
    required this.type,
    required this.timestamp,
    required this.timeOffset,
    required this.roundId,
    required this.createdBy,
    required this.data,
  });

  factory MatchRecord.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return MatchRecord(
      id: doc.id,
      teamId: data['teamId'] ?? '',
      teamType: data['teamType'] ?? '',
      type: data['type'] ?? '',
      timestamp: data['timestamp'] ?? Timestamp.now(),
      timeOffset: data['timeOffset'] ?? 0,
      roundId: data['roundId'] ?? '',
      createdBy: data['createdBy'] ?? '',
      data: data,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'teamId': teamId,
      'teamType': teamType,
      'type': type,
      'timestamp': timestamp,
      'timeOffset': timeOffset,
      'roundId': roundId,
      'createdBy': createdBy,
      ...data,
    };
  }
}
