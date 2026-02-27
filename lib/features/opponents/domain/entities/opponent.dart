/// 상대팀 엔티티 (teams/{teamId}/opponents/{opponentId})
/// Match의 OpponentInfo와 달리 전적/기록 관리용
class Opponent {
  const Opponent({
    required this.opponentId,
    this.name,
    this.contact,
    this.status,
    this.recentResults,
    this.records,
    this.createdAt,
    this.updatedAt,
  });

  final String opponentId;
  final String? name;
  final String? contact;
  /// 'seeking' | 'confirmed'
  final String? status;
  /// 최근 경기 결과 요약 (예: ['W','D','L'])
  final List<String>? recentResults;
  /// 전적 { wins, draws, losses }
  final OpponentRecords? records;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Opponent copyWith({
    String? opponentId,
    String? name,
    String? contact,
    String? status,
    List<String>? recentResults,
    OpponentRecords? records,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Opponent(
      opponentId: opponentId ?? this.opponentId,
      name: name ?? this.name,
      contact: contact ?? this.contact,
      status: status ?? this.status,
      recentResults: recentResults ?? this.recentResults,
      records: records ?? this.records,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// 상대팀 전적
class OpponentRecords {
  const OpponentRecords({
    this.wins = 0,
    this.draws = 0,
    this.losses = 0,
  });

  final int wins;
  final int draws;
  final int losses;

  int get total => wins + draws + losses;
}
