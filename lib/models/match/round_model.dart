import 'package:cloud_firestore/cloud_firestore.dart';

// ✅ RoundModel: matches/{matchId}/rounds/{roundId}
class RoundModel {
  final String id;
  final String matchId;
  final String teamId;
  final int roundNumber;
  final Timestamp startTime;
  final Timestamp endTime;
  final Map<String, dynamic> score; // {home: 2, away: 1}
  final String status;
  final Timestamp createdAt;

  RoundModel({
    required this.id,
    required this.matchId,
    required this.teamId,
    required this.roundNumber,
    required this.startTime,
    required this.endTime,
    required this.score,
    required this.status,
    required this.createdAt,
  });

  factory RoundModel.fromDoc(String matchId, dynamic doc) {
    final data = doc.data() as Map<String, dynamic>;
    return RoundModel(
      id: doc.id,
      matchId: matchId,
      teamId: data['teamId'] ?? '',
      roundNumber: data['roundNumber'] ?? 1,
      startTime: data['startTime'] ?? Timestamp.now(),
      endTime: data['endTime'] ?? Timestamp.now(),
      score: Map<String, dynamic>.from(data['score'] ?? {'home': 0, 'away': 0}),
      status: data['status'] ?? 'notStarted',
      createdAt: data['createdAt'] ?? Timestamp.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'teamId': teamId,
      'roundNumber': roundNumber,
      'startTime': startTime,
      'endTime': endTime,
      'score': score,
      'status': status,
      'createdAt': createdAt,
    };
  }
}
