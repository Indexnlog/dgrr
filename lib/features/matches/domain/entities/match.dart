/// 상대팀 정보
class OpponentInfo {
  const OpponentInfo({
    this.teamId,
    this.name,
    this.contact,
    this.status,
  });

  final String? teamId;
  final String? name;
  final String? contact;
  /// 'seeking' | 'confirmed'
  final String? status;

  OpponentInfo copyWith({
    String? teamId,
    String? name,
    String? contact,
    String? status,
  }) {
    return OpponentInfo(
      teamId: teamId ?? this.teamId,
      name: name ?? this.name,
      contact: contact ?? this.contact,
      status: status ?? this.status,
    );
  }

  bool get isConfirmed => status == 'confirmed';
  bool get isSeeking => status == 'seeking';
}

/// 경기 엔티티
class Match {
  const Match({
    required this.matchId,
    this.matchType,
    this.date,
    this.startTime,
    this.endTime,
    this.location,
    this.status,
    this.gameStatus,
    this.minPlayers,
    this.isTimeConfirmed,
    this.opponent,
    this.registerStart,
    this.registerEnd,
    this.participants,
    this.attendees,
    this.absentees,
    this.absenceReasons,
    this.ballBringers,
    this.lineup,
    this.lineupSize,
    this.captainId,
    this.lineupAnnouncedAt,
    this.createdBy,
    this.createdAt,
    this.updatedAt,
    // 하위 호환용 (점진적 폐기 예정)
    this.teamName,
    this.recruitStatus,
  });

  final String matchId;
  /// 'regular' (정기) | 'irregular' (비정기)
  final String? matchType;
  final DateTime? date;
  final String? startTime;
  final String? endTime;
  final String? location;
  final MatchStatus? status;
  final GameStatus? gameStatus;
  /// 경기 성사 최소 인원 (기본값 7)
  final int? minPlayers;
  /// 경기 시간 확정 여부
  final bool? isTimeConfirmed;
  /// 상대팀 정보
  final OpponentInfo? opponent;
  final DateTime? registerStart;
  final DateTime? registerEnd;
  final List<String>? participants;
  final List<String>? attendees;
  final List<String>? absentees;
  /// 불참 사유 { uid: { reason: String, timestamp: DateTime } }
  final Map<String, dynamic>? absenceReasons;
  /// 공 가져가기 자원자 UID 배열 ("저도 들고가요" 방식)
  final List<String>? ballBringers;
  /// 선발 순서 (UID 배열, 앞 N명이 필드)
  final List<String>? lineup;
  /// 필드 선수 수 (기본 5, 풋살)
  final int? lineupSize;
  /// 당일 주장 UID (감독이 지정)
  final String? captainId;
  /// 라인업 공개 시각 (설정 시 이 시각 이후에만 공개)
  final DateTime? lineupAnnouncedAt;
  final String? createdBy;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  // ── 하위 호환 (점진적 폐기) ──
  @Deprecated('opponent.name 사용')
  final String? teamName;
  @Deprecated('opponent.status 사용')
  final RecruitStatus? recruitStatus;

  /// 상대팀 이름 (opponent.name 우선, 없으면 teamName 폴백)
  String? get opponentName => opponent?.name ?? teamName;

  /// 실효 minPlayers (기본값 7)
  int get effectiveMinPlayers => minPlayers ?? 7;

  /// 현재 참석 인원이 최소 인원 이상인지
  bool get hasEnoughPlayers =>
      (attendees?.length ?? 0) >= effectiveMinPlayers;

  /// 필드 선수 수 (기본 5, 풋살)
  int get effectiveLineupSize => lineupSize ?? 5;

  Match copyWith({
    String? matchId,
    String? matchType,
    DateTime? date,
    String? startTime,
    String? endTime,
    String? location,
    MatchStatus? status,
    GameStatus? gameStatus,
    int? minPlayers,
    bool? isTimeConfirmed,
    OpponentInfo? opponent,
    DateTime? registerStart,
    DateTime? registerEnd,
    List<String>? participants,
    List<String>? attendees,
    List<String>? absentees,
    Map<String, dynamic>? absenceReasons,
    List<String>? ballBringers,
    List<String>? lineup,
    int? lineupSize,
    String? captainId,
    DateTime? lineupAnnouncedAt,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? teamName,
    RecruitStatus? recruitStatus,
  }) {
    return Match(
      matchId: matchId ?? this.matchId,
      matchType: matchType ?? this.matchType,
      date: date ?? this.date,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      location: location ?? this.location,
      status: status ?? this.status,
      gameStatus: gameStatus ?? this.gameStatus,
      minPlayers: minPlayers ?? this.minPlayers,
      isTimeConfirmed: isTimeConfirmed ?? this.isTimeConfirmed,
      opponent: opponent ?? this.opponent,
      registerStart: registerStart ?? this.registerStart,
      registerEnd: registerEnd ?? this.registerEnd,
      participants: participants ?? this.participants,
      attendees: attendees ?? this.attendees,
      absentees: absentees ?? this.absentees,
      absenceReasons: absenceReasons ?? this.absenceReasons,
      ballBringers: ballBringers ?? this.ballBringers,
      lineup: lineup ?? this.lineup,
      lineupSize: lineupSize ?? this.lineupSize,
      captainId: captainId ?? this.captainId,
      lineupAnnouncedAt: lineupAnnouncedAt ?? this.lineupAnnouncedAt,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      teamName: teamName ?? this.teamName,
      recruitStatus: recruitStatus ?? this.recruitStatus,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Match && other.matchId == matchId;
  }

  @override
  int get hashCode => matchId.hashCode;
}

/// 경기 상태
enum MatchStatus {
  /// 초안 — 아직 인원/상대 미확정
  pending,
  /// 인원 충족으로 자동 성사
  fixed,
  /// 운영진이 수동 확정
  confirmed,
  /// 경기 진행 중
  inProgress,
  /// 종료
  finished,
  /// 취소
  cancelled;

  String get value {
    switch (this) {
      case MatchStatus.pending:
        return 'pending';
      case MatchStatus.fixed:
        return 'fixed';
      case MatchStatus.confirmed:
        return 'confirmed';
      case MatchStatus.inProgress:
        return 'inProgress';
      case MatchStatus.finished:
        return 'finished';
      case MatchStatus.cancelled:
        return 'cancelled';
    }
  }

  static MatchStatus? fromString(String? value) {
    if (value == null) return null;
    switch (value) {
      case 'pending':
      case 'draft': // 하위 호환
        return MatchStatus.pending;
      case 'fixed':
        return MatchStatus.fixed;
      case 'confirmed':
        return MatchStatus.confirmed;
      case 'inProgress':
        return MatchStatus.inProgress;
      case 'finished':
        return MatchStatus.finished;
      case 'cancelled':
        return MatchStatus.cancelled;
      default:
        return null;
    }
  }
}

/// 경기 진행 상태
enum GameStatus {
  notStarted,
  playing,
  finished;

  String get value {
    switch (this) {
      case GameStatus.notStarted:
        return 'notStarted';
      case GameStatus.playing:
        return 'playing';
      case GameStatus.finished:
        return 'finished';
    }
  }

  static GameStatus? fromString(String? value) {
    if (value == null) return null;
    switch (value) {
      case 'notStarted':
        return GameStatus.notStarted;
      case 'playing':
        return GameStatus.playing;
      case 'finished':
        return GameStatus.finished;
      default:
        return null;
    }
  }
}

/// @deprecated opponent.status로 대체 예정
enum RecruitStatus {
  confirmed,
  pending;

  String get value {
    switch (this) {
      case RecruitStatus.confirmed:
        return 'confirmed';
      case RecruitStatus.pending:
        return 'pending';
    }
  }

  static RecruitStatus? fromString(String? value) {
    if (value == null) return null;
    switch (value) {
      case 'confirmed':
        return RecruitStatus.confirmed;
      case 'pending':
        return RecruitStatus.pending;
      default:
        return null;
    }
  }
}
