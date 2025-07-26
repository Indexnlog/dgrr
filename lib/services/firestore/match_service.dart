import 'package:cloud_firestore/cloud_firestore.dart';

class MatchService {
  final String matchId;
  MatchService(this.matchId);

  CollectionReference get _recordsRef => FirebaseFirestore.instance
      .collection('matches')
      .doc(matchId)
      .collection('records');

  /// 득점 기록 추가
  Future<void> addGoalRecord(String playerId, String memo, int offset) async {
    await _recordsRef.add({
      'type': 'goal',
      'playerName': playerId,
      'timeOffset': offset,
      'memo': memo,
      'createdAt': Timestamp.now(),
    });
  }

  /// 교체 기록 추가
  Future<void> addChangeRecord(
    String outPlayerId,
    String inPlayerId,
    String memo,
    int offset,
  ) async {
    await _recordsRef.add({
      'type': 'change',
      'outPlayerName': outPlayerId,
      'inPlayerName': inPlayerId,
      'timeOffset': offset,
      'memo': memo,
      'createdAt': Timestamp.now(),
    });
  }

  /// 기록 메모 수정
  Future<void> updateRecordMemo(String recordId, String newMemo) async {
    await _recordsRef.doc(recordId).update({'memo': newMemo});
  }

  /// 기록 삭제
  Future<void> deleteRecord(String recordId) async {
    await _recordsRef.doc(recordId).delete();
  }

  /// 경기 상태 업데이트 (시작/종료)
  Future<void> updateGameStatus(String newStatus) async {
    final now = Timestamp.now();
    final matchRef = FirebaseFirestore.instance
        .collection('matches')
        .doc(matchId);
    if (newStatus == 'inProgress') {
      await matchRef.update({'gameStatus': 'inProgress', 'startTime': now});
    } else if (newStatus == 'finished') {
      await matchRef.update({'gameStatus': 'finished', 'endTime': now});
    }
  }
}
