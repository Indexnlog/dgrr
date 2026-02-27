import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/match.dart';
import '../models/match_model.dart';

/// 투표 결과: 상태 전이가 발생했는지 알려주는 값
class VoteResult {
  const VoteResult({
    required this.previousStatus,
    required this.newStatus,
    required this.attendeeCount,
    required this.minPlayers,
  });

  final String? previousStatus;
  final String? newStatus;
  final int attendeeCount;
  final int minPlayers;

  /// pending -> fixed 전환이 발생했는지
  bool get didBecomeFixed =>
      previousStatus == 'pending' && newStatus == 'fixed';

  /// fixed -> pending 롤백이 발생했는지
  bool get didLoseQuorum =>
      previousStatus == 'fixed' && newStatus == 'pending';
}

/// 경기 Firestore 데이터소스
class MatchRemoteDataSource {
  MatchRemoteDataSource({required this.firestore});

  final FirebaseFirestore firestore;

  CollectionReference<Map<String, dynamic>> _matchesRef(String teamId) =>
      firestore.collection('teams').doc(teamId).collection('matches');

  /// 최근 완료된 경기 목록 (출석 통계용)
  Stream<List<MatchModel>> watchRecentFinishedMatches(
    String teamId, {
    int limit = 20,
  }) {
    return _matchesRef(teamId)
        .where('status', whereIn: ['finished', 'inProgress'])
        .orderBy('date', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => MatchModel.fromFirestore(doc.id, doc.data()))
            .toList());
  }

  /// 기간별 경기 목록 실시간 스트림 (캘린더 월 표시용)
  Stream<List<MatchModel>> watchMatchesInRange(
    String teamId,
    DateTime start,
    DateTime end,
  ) {
    return _matchesRef(teamId)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('date', isLessThanOrEqualTo: Timestamp.fromDate(end))
        .orderBy('date')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => MatchModel.fromFirestore(doc.id, doc.data()))
            .toList());
  }

  /// 다음(미래) 경기 목록 실시간 스트림 — date 오름차순, 오늘 이후만
  /// limit: 페이지네이션 (기본 30건)
  Stream<List<MatchModel>> watchUpcomingMatches(
    String teamId, {
    int limit = 30,
  }) {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);

    return _matchesRef(teamId)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(todayStart))
        .orderBy('date')
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => MatchModel.fromFirestore(doc.id, doc.data()))
            .toList());
  }

  /// 참석 투표 (트랜잭션: attendees 추가 + 자동 성사 전환)
  Future<VoteResult> voteAttend(
    String teamId,
    String matchId,
    String uid,
  ) async {
    final ref = _matchesRef(teamId).doc(matchId);

    return firestore.runTransaction<VoteResult>((tx) async {
      final snap = await tx.get(ref);
      if (!snap.exists) {
        throw Exception('경기 문서가 존재하지 않습니다');
      }
      final data = snap.data()!;

      final attendees = Set<String>.from(data['attendees'] ?? []);
      final absentees = Set<String>.from(data['absentees'] ?? []);
      var lateAttendees = List<String>.from(data['lateAttendees'] ?? []);
      var lateReasons = Map<String, String>.from(
        (data['lateReasons'] as Map?)?.map((k, v) => MapEntry(k.toString(), v.toString())) ?? {},
      );

      attendees.add(uid);
      absentees.remove(uid);
      lateAttendees.remove(uid);
      lateReasons.remove(uid);

      final minPlayers = data['minPlayers'] as int? ?? 7;
      final previousStatus = data['status'] as String?;
      var newStatus = previousStatus;

      // 자동 성사: pending 상태에서 인원 충족 시 fixed로 전환
      if (attendees.length >= minPlayers && previousStatus == 'pending') {
        newStatus = 'fixed';
      }

      tx.update(ref, {
        'attendees': attendees.toList(),
        'absentees': absentees.toList(),
        'lateAttendees': lateAttendees,
        'lateReasons': lateReasons,
        'status': newStatus,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return VoteResult(
        previousStatus: previousStatus,
        newStatus: newStatus,
        attendeeCount: attendees.length,
        minPlayers: minPlayers,
      );
    });
  }

  /// 지각 참석 투표 (참석 + 지각 예상 시간)
  Future<VoteResult> voteAttendLate(
    String teamId,
    String matchId,
    String uid,
    String lateTime,
  ) async {
    final ref = _matchesRef(teamId).doc(matchId);

    return firestore.runTransaction<VoteResult>((tx) async {
      final snap = await tx.get(ref);
      if (!snap.exists) throw Exception('경기 문서가 존재하지 않습니다');
      final data = snap.data()!;

      final attendees = Set<String>.from(data['attendees'] ?? []);
      final absentees = Set<String>.from(data['absentees'] ?? []);
      final lateAttendees = List<String>.from(data['lateAttendees'] ?? []);
      final lateReasons = Map<String, String>.from(
        (data['lateReasons'] as Map?)?.map((k, v) => MapEntry(k.toString(), v.toString())) ?? {},
      );

      attendees.add(uid);
      absentees.remove(uid);
      if (!lateAttendees.contains(uid)) lateAttendees.add(uid);
      lateReasons[uid] = lateTime;

      final minPlayers = data['minPlayers'] as int? ?? 7;
      final previousStatus = data['status'] as String?;
      var newStatus = previousStatus;
      if (attendees.length >= minPlayers && previousStatus == 'pending') {
        newStatus = 'fixed';
      }

      tx.update(ref, {
        'attendees': attendees.toList(),
        'absentees': absentees.toList(),
        'lateAttendees': lateAttendees,
        'lateReasons': lateReasons,
        'status': newStatus,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return VoteResult(
        previousStatus: previousStatus,
        newStatus: newStatus,
        attendeeCount: attendees.length,
        minPlayers: minPlayers,
      );
    });
  }

  /// 불참 투표 (트랜잭션: absentees 추가 + 성사 롤백)
  Future<VoteResult> voteAbsent(
    String teamId,
    String matchId,
    String uid,
  ) async {
    final ref = _matchesRef(teamId).doc(matchId);

    return firestore.runTransaction<VoteResult>((tx) async {
      final snap = await tx.get(ref);
      if (!snap.exists) {
        throw Exception('경기 문서가 존재하지 않습니다');
      }
      final data = snap.data()!;

      final attendees = Set<String>.from(data['attendees'] ?? []);
      final absentees = Set<String>.from(data['absentees'] ?? []);
      var lateAttendees = List<String>.from(data['lateAttendees'] ?? []);
      var lateReasons = Map<String, String>.from(
        (data['lateReasons'] as Map?)?.map((k, v) => MapEntry(k.toString(), v.toString())) ?? {},
      );

      attendees.remove(uid);
      absentees.add(uid);
      lateAttendees.remove(uid);
      lateReasons.remove(uid);

      final minPlayers = data['minPlayers'] as int? ?? 7;
      final previousStatus = data['status'] as String?;
      var newStatus = previousStatus;

      // 인원 미달 시 fixed -> pending 롤백
      if (attendees.length < minPlayers && previousStatus == 'fixed') {
        newStatus = 'pending';
      }

      tx.update(ref, {
        'attendees': attendees.toList(),
        'absentees': absentees.toList(),
        'lateAttendees': lateAttendees,
        'lateReasons': lateReasons,
        'status': newStatus,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return VoteResult(
        previousStatus: previousStatus,
        newStatus: newStatus,
        attendeeCount: attendees.length,
        minPlayers: minPlayers,
      );
    });
  }

  /// 불참 투표 + 사유 저장 (당일 변경 시)
  Future<VoteResult> voteAbsentWithReason(
    String teamId,
    String matchId,
    String uid,
    String reason,
  ) async {
    final ref = _matchesRef(teamId).doc(matchId);

    return firestore.runTransaction<VoteResult>((tx) async {
      final snap = await tx.get(ref);
      if (!snap.exists) {
        throw Exception('경기 문서가 존재하지 않습니다');
      }
      final data = snap.data()!;

      final attendees = Set<String>.from(data['attendees'] ?? []);
      final absentees = Set<String>.from(data['absentees'] ?? []);
      var lateAttendees = List<String>.from(data['lateAttendees'] ?? []);
      var lateReasons = Map<String, String>.from(
        (data['lateReasons'] as Map?)?.map((k, v) => MapEntry(k.toString(), v.toString())) ?? {},
      );

      attendees.remove(uid);
      absentees.add(uid);
      lateAttendees.remove(uid);
      lateReasons.remove(uid);

      final minPlayers = data['minPlayers'] as int? ?? 7;
      final previousStatus = data['status'] as String?;
      var newStatus = previousStatus;

      if (attendees.length < minPlayers && previousStatus == 'fixed') {
        newStatus = 'pending';
      }

      // 불참 사유를 absenceReasons 맵에 저장
      final absenceReasons =
          Map<String, dynamic>.from(data['absenceReasons'] ?? {});
      absenceReasons[uid] = {
        'reason': reason,
        'timestamp': FieldValue.serverTimestamp(),
      };

      tx.update(ref, {
        'attendees': attendees.toList(),
        'absentees': absentees.toList(),
        'lateAttendees': lateAttendees,
        'lateReasons': lateReasons,
        'absenceReasons': absenceReasons,
        'status': newStatus,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return VoteResult(
        previousStatus: previousStatus,
        newStatus: newStatus,
        attendeeCount: attendees.length,
        minPlayers: minPlayers,
      );
    });
  }

  /// 공 가져가기 자원 토글 ("저도 들고가요" 방식)
  Future<void> toggleBallBringer(
    String teamId,
    String matchId,
    String uid,
  ) async {
    final ref = _matchesRef(teamId).doc(matchId);

    await firestore.runTransaction((tx) async {
      final snap = await tx.get(ref);
      if (!snap.exists) throw Exception('경기 문서가 존재하지 않습니다');
      final data = snap.data()!;

      final list = List<String>.from(data['ballBringers'] ?? []);
      if (list.contains(uid)) {
        list.remove(uid);
      } else {
        list.add(uid);
      }

      tx.update(ref, {
        'ballBringers': list,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  /// participants를 attendees와 동기화 (경기 시작 시)
  Future<void> syncParticipantsFromAttendees(
    String teamId,
    String matchId,
  ) async {
    final ref = _matchesRef(teamId).doc(matchId);
    final snap = await ref.get();
    if (!snap.exists) return;

    final data = snap.data()!;
    final attendees = List<String>.from(data['attendees'] ?? []);

    await ref.update({
      'participants': attendees,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// 라인업 업데이트 (감독 전용)
  Future<void> updateLineup(
    String teamId,
    String matchId, {
    required List<String> lineup,
    int? lineupSize,
    String? captainId,
    DateTime? lineupAnnouncedAt,
  }) async {
    await _matchesRef(teamId).doc(matchId).update({
      'lineup': lineup,
      if (lineupSize != null) 'lineupSize': lineupSize,
      if (captainId != null) 'captainId': captainId,
      if (lineupAnnouncedAt != null) 'lineupAnnouncedAt': Timestamp.fromDate(lineupAnnouncedAt),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// 경기 생성
  Future<String> createMatch(
    String teamId, {
    required DateTime date,
    String? startTime,
    String? endTime,
    String? location,
    required String opponentName,
    String? opponentContact,
    String opponentStatus = 'seeking',
    String? opponentId,
    int minPlayers = 7,
    String? createdBy,
  }) async {
    final opponent = OpponentInfoModel(
      teamId: opponentId,
      name: opponentName,
      contact: opponentContact,
      status: opponentStatus,
    );
    final data = {
      'matchType': 'regular',
      'date': Timestamp.fromDate(date),
      'startTime': startTime ?? '18:00',
      'endTime': endTime ?? '20:00',
      'location': location ?? '',
      'status': 'pending',
      'gameStatus': 'notStarted',
      'minPlayers': minPlayers,
      'isTimeConfirmed': false,
      'opponent': opponent.toMap(),
      'teamName': opponentName,
      'attendees': <String>[],
      'absentees': <String>[],
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      if (createdBy != null) 'createdBy': createdBy,
    };
    final docRef = await _matchesRef(teamId).add(data);
    return docRef.id;
  }

  /// 상대팀 정보 수정
  Future<void> updateOpponent(
    String teamId,
    String matchId, {
    String? name,
    String? contact,
    String? status,
  }) async {
    final updates = <String, dynamic>{
      'updatedAt': FieldValue.serverTimestamp(),
    };
    final ref = _matchesRef(teamId).doc(matchId);
    final snap = await ref.get();
    if (!snap.exists) return;

    final data = snap.data()!;
    final opponent = Map<String, dynamic>.from(data['opponent'] as Map? ?? {});
    if (name != null) opponent['name'] = name;
    if (contact != null) opponent['contact'] = contact;
    if (status != null) opponent['status'] = status;
    updates['opponent'] = opponent;
    if (name != null) updates['teamName'] = name;

    await ref.update(updates);
  }

  /// 샘플 경기 1건 삽입 (에뮬레이터 테스트용)
  Future<void> seedSampleMatch(String teamId) async {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final futureDocs = await _matchesRef(teamId)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(todayStart))
        .limit(1)
        .get();
    if (futureDocs.docs.isNotEmpty) return;

    final nextSunday = _nextNthSunday(2);

    final sample = MatchModel(
      matchId: '',
      matchType: 'regular',
      date: nextSunday,
      startTime: '18:00',
      endTime: '20:00',
      location: '석수 다목적구장',
      status: MatchStatus.pending,
      gameStatus: GameStatus.notStarted,
      minPlayers: 7,
      isTimeConfirmed: false,
      opponent: const OpponentInfoModel(
        name: '스마일리',
        status: 'seeking',
      ),
      attendees: const [],
      absentees: const [],
      createdAt: DateTime.now(),
    );

    await _matchesRef(teamId).add(sample.toFirestore());
  }

  /// n번째(2 또는 4) 주차 일요일 중 오늘 이후로 가장 가까운 날짜
  DateTime _nextNthSunday(int targetWeek) {
    final now = DateTime.now();
    var candidate = DateTime(now.year, now.month, 1);

    while (candidate.weekday != DateTime.sunday) {
      candidate = candidate.add(const Duration(days: 1));
    }

    final week2 = candidate.add(const Duration(days: 7));
    final week4 = candidate.add(const Duration(days: 21));

    if (week2.isAfter(now)) return week2;
    if (week4.isAfter(now)) return week4;

    var nextMonth = DateTime(now.year, now.month + 1, 1);
    while (nextMonth.weekday != DateTime.sunday) {
      nextMonth = nextMonth.add(const Duration(days: 1));
    }
    return nextMonth.add(const Duration(days: 7));
  }
}
