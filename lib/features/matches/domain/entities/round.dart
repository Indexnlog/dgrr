
/// 경기 라운드 엔티티
class Round {
  const Round({
    required this.roundId,
    this.roundIndex,
    this.status,
    this.startTime,
    this.endTime,
    this.ourScore,
    this.oppScore,
    this.createdAt,
    this.createdBy,
  });

  final String roundId;
  final int? roundIndex;
  final RoundStatus? status;
  final DateTime? startTime;
  final DateTime? endTime;
  final int? ourScore;
  final int? oppScore;
  final DateTime? createdAt;
  final String? createdBy;

  Round copyWith({
    String? roundId,
    int? roundIndex,
    RoundStatus? status,
    DateTime? startTime,
    DateTime? endTime,
    int? ourScore,
    int? oppScore,
    DateTime? createdAt,
    String? createdBy,
  }) {
    return Round(
      roundId: roundId ?? this.roundId,
      roundIndex: roundIndex ?? this.roundIndex,
      status: status ?? this.status,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      ourScore: ourScore ?? this.ourScore,
      oppScore: oppScore ?? this.oppScore,
      createdAt: createdAt ?? this.createdAt,
      createdBy: createdBy ?? this.createdBy,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Round && other.roundId == roundId;
  }

  @override
  int get hashCode => roundId.hashCode;
}

enum RoundStatus {
  notStarted,
  playing,
  finished;

  String get value {
    switch (this) {
      case RoundStatus.notStarted:
        return 'not_started';
      case RoundStatus.playing:
        return 'playing';
      case RoundStatus.finished:
        return 'finished';
    }
  }

  static RoundStatus? fromString(String? value) {
    if (value == null) return null;
    switch (value) {
      case 'not_started':
        return RoundStatus.notStarted;
      case 'playing':
        return RoundStatus.playing;
      case 'finished':
        return RoundStatus.finished;
      default:
        return null;
    }
  }
}
