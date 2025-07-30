import 'package:cloud_firestore/cloud_firestore.dart';

// ✅ RecordModel: matches/{matchId}/rounds/{roundId}/records/{recordId}
class RecordModel {
  final String id;
  final String teamId;
  final String roundId;
  final String type; // goal or substitution
  final String teamType; // our or opponent
  final Timestamp timestamp;
  final int timeOffset;
  final String createdBy;

  // goal
  final String? playerId;
  final String? playerName;
  final int? playerNumber;
  final String? goalType;
  final bool? isOwnGoal;
  final String? assistPlayerId;
  final String? assistPlayerName;
  final int? scoreAfterGoal;

  // substitution
  final String? inPlayerId;
  final String? inPlayerName;
  final int? inPlayerNumber;
  final String? outPlayerId;
  final String? outPlayerName;
  final int? outPlayerNumber;

  RecordModel({
    required this.id,
    required this.teamId,
    required this.roundId,
    required this.type,
    required this.teamType,
    required this.timestamp,
    required this.timeOffset,
    required this.createdBy,
    this.playerId,
    this.playerName,
    this.playerNumber,
    this.goalType,
    this.isOwnGoal,
    this.assistPlayerId,
    this.assistPlayerName,
    this.scoreAfterGoal,
    this.inPlayerId,
    this.inPlayerName,
    this.inPlayerNumber,
    this.outPlayerId,
    this.outPlayerName,
    this.outPlayerNumber,
  });

  factory RecordModel.fromDoc(dynamic doc) {
    final data = doc.data() as Map<String, dynamic>;
    return RecordModel(
      id: doc.id,
      teamId: data['teamId'] ?? '',
      roundId: data['roundId'] ?? '',
      type: data['type'] ?? '',
      teamType: data['teamType'] ?? '',
      timestamp: data['timestamp'] ?? Timestamp.now(),
      timeOffset: data['timeOffset'] ?? 0,
      createdBy: data['createdBy'] ?? '',
      playerId: data['playerId'],
      playerName: data['playerName'],
      playerNumber: data['playerNumber'],
      goalType: data['goalType'],
      isOwnGoal: data['isOwnGoal'],
      assistPlayerId: data['assistPlayerId'],
      assistPlayerName: data['assistPlayerName'],
      scoreAfterGoal: data['scoreAfterGoal'],
      inPlayerId: data['inPlayerId'],
      inPlayerName: data['inPlayerName'],
      inPlayerNumber: data['inPlayerNumber'],
      outPlayerId: data['outPlayerId'],
      outPlayerName: data['outPlayerName'],
      outPlayerNumber: data['outPlayerNumber'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'teamId': teamId,
      'roundId': roundId,
      'type': type,
      'teamType': teamType,
      'timestamp': timestamp,
      'timeOffset': timeOffset,
      'createdBy': createdBy,
      'playerId': playerId,
      'playerName': playerName,
      'playerNumber': playerNumber,
      'goalType': goalType,
      'isOwnGoal': isOwnGoal,
      'assistPlayerId': assistPlayerId,
      'assistPlayerName': assistPlayerName,
      'scoreAfterGoal': scoreAfterGoal,
      'inPlayerId': inPlayerId,
      'inPlayerName': inPlayerName,
      'inPlayerNumber': inPlayerNumber,
      'outPlayerId': outPlayerId,
      'outPlayerName': outPlayerName,
      'outPlayerNumber': outPlayerNumber,
    };
  }
}
