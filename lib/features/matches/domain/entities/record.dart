/// 경기 기록 엔티티 (골, 교체 등)
abstract class Record {
  const Record({
    required this.recordId,
    required this.type,
    required this.teamType,
    required this.timeOffset,
    required this.timestamp,
    this.createdBy,
  });

  final String recordId;
  final RecordType type;
  final TeamType teamType;
  final int timeOffset;
  final DateTime timestamp;
  final String? createdBy;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Record && other.recordId == recordId;
  }

  @override
  int get hashCode => recordId.hashCode;
}

/// 골 기록
class GoalRecord extends Record {
  const GoalRecord({
    required super.recordId,
    required super.teamType,
    required super.timeOffset,
    required super.timestamp,
    super.createdBy,
    this.playerId,
    this.playerName,
    this.playerNumber,
    this.assistPlayerId,
    this.assistPlayerName,
    this.goalType,
    this.isOwnGoal,
    this.scoreAfterGoal,
  }) : super(type: RecordType.goal);

  final String? playerId;
  final String? playerName;
  final int? playerNumber;
  final String? assistPlayerId;
  final String? assistPlayerName;
  final String? goalType;
  final bool? isOwnGoal;
  final int? scoreAfterGoal;

  GoalRecord copyWith({
    String? recordId,
    TeamType? teamType,
    int? timeOffset,
    DateTime? timestamp,
    String? createdBy,
    String? playerId,
    String? playerName,
    int? playerNumber,
    String? assistPlayerId,
    String? assistPlayerName,
    String? goalType,
    bool? isOwnGoal,
    int? scoreAfterGoal,
  }) {
    return GoalRecord(
      recordId: recordId ?? this.recordId,
      teamType: teamType ?? this.teamType,
      timeOffset: timeOffset ?? this.timeOffset,
      timestamp: timestamp ?? this.timestamp,
      createdBy: createdBy ?? this.createdBy,
      playerId: playerId ?? this.playerId,
      playerName: playerName ?? this.playerName,
      playerNumber: playerNumber ?? this.playerNumber,
      assistPlayerId: assistPlayerId ?? this.assistPlayerId,
      assistPlayerName: assistPlayerName ?? this.assistPlayerName,
      goalType: goalType ?? this.goalType,
      isOwnGoal: isOwnGoal ?? this.isOwnGoal,
      scoreAfterGoal: scoreAfterGoal ?? this.scoreAfterGoal,
    );
  }
}

/// 교체 기록
class SubstitutionRecord extends Record {
  const SubstitutionRecord({
    required super.recordId,
    required super.teamType,
    required super.timeOffset,
    required super.timestamp,
    super.createdBy,
    this.inPlayerId,
    this.inPlayerName,
    this.inPlayerNumber,
    this.outPlayerId,
    this.outPlayerName,
    this.outPlayerNumber,
  }) : super(type: RecordType.substitution);

  final String? inPlayerId;
  final String? inPlayerName;
  final int? inPlayerNumber;
  final String? outPlayerId;
  final String? outPlayerName;
  final int? outPlayerNumber;

  SubstitutionRecord copyWith({
    String? recordId,
    TeamType? teamType,
    int? timeOffset,
    DateTime? timestamp,
    String? createdBy,
    String? inPlayerId,
    String? inPlayerName,
    int? inPlayerNumber,
    String? outPlayerId,
    String? outPlayerName,
    int? outPlayerNumber,
  }) {
    return SubstitutionRecord(
      recordId: recordId ?? this.recordId,
      teamType: teamType ?? this.teamType,
      timeOffset: timeOffset ?? this.timeOffset,
      timestamp: timestamp ?? this.timestamp,
      createdBy: createdBy ?? this.createdBy,
      inPlayerId: inPlayerId ?? this.inPlayerId,
      inPlayerName: inPlayerName ?? this.inPlayerName,
      inPlayerNumber: inPlayerNumber ?? this.inPlayerNumber,
      outPlayerId: outPlayerId ?? this.outPlayerId,
      outPlayerName: outPlayerName ?? this.outPlayerName,
      outPlayerNumber: outPlayerNumber ?? this.outPlayerNumber,
    );
  }
}

enum RecordType {
  goal,
  substitution,
  card,
  assist;

  String get value {
    switch (this) {
      case RecordType.goal:
        return 'goal';
      case RecordType.substitution:
        return 'substitution';
      case RecordType.card:
        return 'card';
      case RecordType.assist:
        return 'assist';
    }
  }

  static RecordType? fromString(String? value) {
    if (value == null) return null;
    switch (value) {
      case 'goal':
        return RecordType.goal;
      case 'substitution':
        return RecordType.substitution;
      case 'card':
        return RecordType.card;
      case 'assist':
        return RecordType.assist;
      default:
        return null;
    }
  }
}

enum TeamType {
  our,
  opponent;

  String get value {
    switch (this) {
      case TeamType.our:
        return 'our';
      case TeamType.opponent:
        return 'opponent';
    }
  }

  static TeamType? fromString(String? value) {
    if (value == null) return null;
    switch (value) {
      case 'our':
        return TeamType.our;
      case 'opponent':
        return TeamType.opponent;
      default:
        return null;
    }
  }
}
