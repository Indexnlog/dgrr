import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/record.dart';
import '../../domain/entities/round.dart';
import '../models/record_model.dart';
import '../models/round_model.dart';

/// 라운드·기록 Firestore 데이터소스
class RoundRecordDataSource {
  RoundRecordDataSource({required this.firestore});

  final FirebaseFirestore firestore;

  CollectionReference<Map<String, dynamic>> _roundsRef(
    String teamId,
    String matchId,
  ) =>
      firestore
          .collection('teams')
          .doc(teamId)
          .collection('matches')
          .doc(matchId)
          .collection('rounds');

  DocumentReference<Map<String, dynamic>> _matchRef(
    String teamId,
    String matchId,
  ) =>
      firestore.collection('teams').doc(teamId).collection('matches').doc(matchId);

  CollectionReference<Map<String, dynamic>> _recordsRef(
    String teamId,
    String matchId,
    String roundId,
  ) =>
      _roundsRef(teamId, matchId).doc(roundId).collection('records');

  // ── 라운드 ──

  Stream<List<RoundModel>> watchRounds(String teamId, String matchId) {
    return _roundsRef(teamId, matchId)
        .orderBy('roundIndex')
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => RoundModel.fromFirestore(doc.id, doc.data()))
            .toList());
  }

  Future<RoundModel> createRound(
    String teamId,
    String matchId,
    int roundIndex,
  ) async {
    final data = {
      'roundIndex': roundIndex,
      'status': 'not_started',
      'score': {'our': 0, 'opp': 0},
      'createdAt': FieldValue.serverTimestamp(),
    };
    final docRef = await _roundsRef(teamId, matchId).add(data);
    return RoundModel(
      roundId: docRef.id,
      roundIndex: roundIndex,
      status: RoundStatus.notStarted,
      createdAt: DateTime.now(),
    );
  }

  Future<void> startRound(
    String teamId,
    String matchId,
    String roundId,
  ) async {
    await _roundsRef(teamId, matchId).doc(roundId).update({
      'status': 'playing',
      'startTime': FieldValue.serverTimestamp(),
    });
  }

  Future<void> endRound(
    String teamId,
    String matchId,
    String roundId,
  ) async {
    await _roundsRef(teamId, matchId).doc(roundId).update({
      'status': 'finished',
      'endTime': FieldValue.serverTimestamp(),
    });
  }

  // ── 기록 ──

  Stream<List<Record>> watchRecords(
    String teamId,
    String matchId,
    String roundId,
  ) {
    return _recordsRef(teamId, matchId, roundId)
        .orderBy('timeOffset')
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => RecordModel.fromFirestore(doc.id, doc.data()))
            .toList());
  }

  /// 골 기록 추가 + 라운드 스코어 트랜잭션 업데이트
  Future<void> addGoalRecord({
    required String teamId,
    required String matchId,
    required String roundId,
    required TeamType teamType,
    required int timeOffset,
    String? playerId,
    String? playerName,
    int? playerNumber,
    String? assistPlayerId,
    String? assistPlayerName,
    String? goalType,
    bool? isOwnGoal,
    String? createdBy,
  }) async {
    final roundRef = _roundsRef(teamId, matchId).doc(roundId);

    await firestore.runTransaction((tx) async {
      final roundSnap = await tx.get(roundRef);
      final scoreMap = Map<String, dynamic>.from(
        roundSnap.data()?['score'] as Map? ?? {'our': 0, 'opp': 0},
      );
      int ourScore = scoreMap['our'] as int? ?? 0;
      int oppScore = scoreMap['opp'] as int? ?? 0;

      // 자책골 처리: 자책골이면 상대 팀에 득점
      if (isOwnGoal == true) {
        if (teamType == TeamType.our) {
          oppScore++;
        } else {
          ourScore++;
        }
      } else {
        if (teamType == TeamType.our) {
          ourScore++;
        } else {
          oppScore++;
        }
      }

      tx.update(roundRef, {
        'score': {'our': ourScore, 'opp': oppScore},
      });

      final recordRef = _recordsRef(teamId, matchId, roundId).doc();
      tx.set(recordRef, {
        'type': 'goal',
        'teamType': teamType.value,
        'timeOffset': timeOffset,
        'timestamp': FieldValue.serverTimestamp(),
        if (playerId != null) 'playerId': playerId,
        if (playerName != null) 'playerName': playerName,
        if (playerNumber != null) 'playerNumber': playerNumber,
        if (assistPlayerId != null) 'assistPlayerId': assistPlayerId,
        if (assistPlayerName != null) 'assistPlayerName': assistPlayerName,
        if (goalType != null) 'goalType': goalType,
        if (isOwnGoal != null) 'isOwnGoal': isOwnGoal,
        'scoreAfterGoal': ourScore + oppScore,
        if (createdBy != null) 'createdBy': createdBy,
      });
    });
  }

  Future<void> addSubstitutionRecord({
    required String teamId,
    required String matchId,
    required String roundId,
    required TeamType teamType,
    required int timeOffset,
    String? inPlayerId,
    String? inPlayerName,
    int? inPlayerNumber,
    String? outPlayerId,
    String? outPlayerName,
    int? outPlayerNumber,
    String? createdBy,
  }) async {
    await _recordsRef(teamId, matchId, roundId).add({
      'type': 'substitution',
      'teamType': teamType.value,
      'timeOffset': timeOffset,
      'timestamp': FieldValue.serverTimestamp(),
      if (inPlayerId != null) 'inPlayerId': inPlayerId,
      if (inPlayerName != null) 'inPlayerName': inPlayerName,
      if (inPlayerNumber != null) 'inPlayerNumber': inPlayerNumber,
      if (outPlayerId != null) 'outPlayerId': outPlayerId,
      if (outPlayerName != null) 'outPlayerName': outPlayerName,
      if (outPlayerNumber != null) 'outPlayerNumber': outPlayerNumber,
      if (createdBy != null) 'createdBy': createdBy,
    });
  }

  Future<void> deleteRecord(
    String teamId,
    String matchId,
    String roundId,
    String recordId,
  ) async {
    await _recordsRef(teamId, matchId, roundId).doc(recordId).delete();
  }

  // ── 경기 상태 ──

  Future<void> startMatch(String teamId, String matchId) async {
    await _matchRef(teamId, matchId).update({
      'status': 'inProgress',
      'gameStatus': 'playing',
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> endMatch(String teamId, String matchId) async {
    await _matchRef(teamId, matchId).update({
      'status': 'finished',
      'gameStatus': 'finished',
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
