import 'package:cloud_firestore/cloud_firestore.dart';

/// 🏷️ 매치 관련 Firestore 서비스
class MatchService {
  final String matchId;
  final String? roundId;

  /// ✅ 라운드 기반 작업 시에는 roundId 필수
  MatchService(this.matchId, [this.roundId]);

  /// 📝 현재 선택된 라운드의 records 컬렉션
  CollectionReference get _recordsRef {
    if (roundId == null) {
      throw Exception('roundId 가 필요합니다.');
    }
    return FirebaseFirestore.instance
        .collection('matches')
        .doc(matchId)
        .collection('rounds')
        .doc(roundId)
        .collection('records');
  }

  // ---------------------------------------------------------------------------
  // 🎯 기록 관리 (득점 / 교체)
  // ---------------------------------------------------------------------------

  /// ✅ 득점 기록 추가
  Future<void> addGoalRecord(
    String playerName,
    String memo,
    int offset,
    String team,
  ) async {
    await _recordsRef.add({
      'type': 'goal',
      'playerName': playerName,
      'timeOffset': offset, // 몇 분 경과했는지
      'team': team, // home / away
      'memo': memo,
      'createdAt': Timestamp.now(),
    });

    // 득점 시 라운드 점수 갱신
    await _updateRoundScore(team, 1);
  }

  /// ✅ 교체 기록 추가
  Future<void> addChangeRecord(
    String outPlayerName,
    String inPlayerName,
    String memo,
    int offset,
    String team,
  ) async {
    await _recordsRef.add({
      'type': 'change',
      'outPlayerName': outPlayerName,
      'inPlayerName': inPlayerName,
      'timeOffset': offset,
      'team': team,
      'memo': memo,
      'createdAt': Timestamp.now(),
    });
    // 교체는 점수 갱신 필요 없음
  }

  /// ✅ 기록 메모 수정
  Future<void> updateRecordMemo(String recordId, String newMemo) async {
    await _recordsRef.doc(recordId).update({'memo': newMemo});
  }

  /// ✅ 기록 삭제
  Future<void> deleteRecord(String recordId) async {
    await _recordsRef.doc(recordId).delete();
  }

  /// 내부 전용: 라운드 점수 갱신
  Future<void> _updateRoundScore(String team, int delta) async {
    if (roundId == null) return;

    final roundRef = FirebaseFirestore.instance
        .collection('matches')
        .doc(matchId)
        .collection('rounds')
        .doc(roundId);

    await FirebaseFirestore.instance.runTransaction((tx) async {
      final snapshot = await tx.get(roundRef);
      if (!snapshot.exists) return;
      final data = snapshot.data() as Map<String, dynamic>;
      final score = Map<String, dynamic>.from(data['score'] ?? {});
      final home = (score['home'] ?? 0) as int;
      final away = (score['away'] ?? 0) as int;

      if (team == 'home') {
        score['home'] = home + delta;
      } else {
        score['away'] = away + delta;
      }

      tx.update(roundRef, {'score': score});
    });
  }

  // ---------------------------------------------------------------------------
  // 🎯 라운드 관리
  // ---------------------------------------------------------------------------

  /// ✅ 라운드 상태 업데이트
  static Future<void> updateRoundStatus(
    String matchId,
    String roundId,
    String status,
  ) async {
    final roundRef = FirebaseFirestore.instance
        .collection('matches')
        .doc(matchId)
        .collection('rounds')
        .doc(roundId);
    await roundRef.update({'status': status});
  }

  /// ✅ 라운드 시작: startTime 기록 + 상태 inProgress
  static Future<void> startRound(String matchId, String roundId) async {
    final roundRef = FirebaseFirestore.instance
        .collection('matches')
        .doc(matchId)
        .collection('rounds')
        .doc(roundId);

    await roundRef.update({
      'startTime': Timestamp.now(),
      'status': 'inProgress',
    });
  }

  /// ✅ 라운드 생성 (자동 ID)
  static Future<void> createRound(String matchId, int roundNumber) async {
    final roundsRef = FirebaseFirestore.instance
        .collection('matches')
        .doc(matchId)
        .collection('rounds');
    await roundsRef.add({
      'roundNumber': roundNumber,
      'status': 'notStarted',
      'score': {'home': 0, 'away': 0},
      'createdAt': Timestamp.now(),
    });
  }

  /// ✅ 라운드 삭제
  static Future<void> deleteRound(String matchId, String roundId) async {
    await FirebaseFirestore.instance
        .collection('matches')
        .doc(matchId)
        .collection('rounds')
        .doc(roundId)
        .delete();
  }

  // ---------------------------------------------------------------------------
  // 🎯 매치 메타정보 업데이트
  // ---------------------------------------------------------------------------

  /// ✅ 상대 팀 업데이트 & recruitStatus를 confirmed로 변경
  static Future<void> updateMatchTeam(String matchId, String teamId) async {
    await FirebaseFirestore.instance.collection('matches').doc(matchId).update({
      'teamId': teamId,
      'recruitStatus': 'confirmed',
    });
  }
}
