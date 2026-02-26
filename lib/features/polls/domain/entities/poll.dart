/// 투표 목적 구분
/// - membership: 월별 등록 여부 (20~24일, 등록/휴회/미등록)
/// - attendance: 일자별 참석 여부 (25~말일, 수업 일정 체크)
/// - match: 매치 참석 투표
/// - general: 기타
enum PollCategory {
  membership,
  attendance,
  match,
  general;

  String get value {
    switch (this) {
      case PollCategory.membership:
        return 'membership';
      case PollCategory.attendance:
        return 'attendance';
      case PollCategory.match:
        return 'match';
      case PollCategory.general:
        return 'general';
    }
  }

  String get label {
    switch (this) {
      case PollCategory.membership:
        return '월별 등록';
      case PollCategory.attendance:
        return '일자별 참석';
      case PollCategory.match:
        return '매치 참석';
      case PollCategory.general:
        return '기타';
    }
  }

  static PollCategory? fromString(String? value) {
    if (value == null) return null;
    switch (value) {
      case 'membership':
        return PollCategory.membership;
      case 'attendance':
        return PollCategory.attendance;
      case 'match':
        return PollCategory.match;
      case 'general':
        return PollCategory.general;
      default:
        return null;
    }
  }
}

/// 투표 엔티티
class Poll {
  const Poll({
    required this.pollId,
    required this.title,
    this.description,
    this.type,
    this.category,
    this.targetMonth,
    this.anonymous,
    this.canChangeVote,
    this.maxSelections,
    this.showResultBeforeDeadline,
    this.isActive,
    this.expiresAt,
    this.resultFinalizedAt,
    this.linkedEventId,
    this.createdBy,
    this.createdAt,
    this.options,
  });

  final String pollId;
  final String title;
  final String? description;
  final PollType? type;
  /// 투표 목적 (월별 등록 / 일자별 참석 / 매치 / 기타)
  final PollCategory? category;
  /// 대상 월 (yyyy-MM, 월별 등록/일자별 참석용)
  final String? targetMonth;
  final bool? anonymous;
  final bool? canChangeVote;
  final int? maxSelections;
  final bool? showResultBeforeDeadline;
  final bool? isActive;
  final DateTime? expiresAt;
  final DateTime? resultFinalizedAt;
  final String? linkedEventId;
  final String? createdBy;
  final DateTime? createdAt;
  final List<PollOption>? options;

  Poll copyWith({
    String? pollId,
    String? title,
    String? description,
    PollType? type,
    PollCategory? category,
    String? targetMonth,
    bool? anonymous,
    bool? canChangeVote,
    int? maxSelections,
    bool? showResultBeforeDeadline,
    bool? isActive,
    DateTime? expiresAt,
    DateTime? resultFinalizedAt,
    String? linkedEventId,
    String? createdBy,
    DateTime? createdAt,
    List<PollOption>? options,
  }) {
    return Poll(
      pollId: pollId ?? this.pollId,
      title: title ?? this.title,
      description: description ?? this.description,
      type: type ?? this.type,
      category: category ?? this.category,
      targetMonth: targetMonth ?? this.targetMonth,
      anonymous: anonymous ?? this.anonymous,
      canChangeVote: canChangeVote ?? this.canChangeVote,
      maxSelections: maxSelections ?? this.maxSelections,
      showResultBeforeDeadline:
          showResultBeforeDeadline ?? this.showResultBeforeDeadline,
      isActive: isActive ?? this.isActive,
      expiresAt: expiresAt ?? this.expiresAt,
      resultFinalizedAt: resultFinalizedAt ?? this.resultFinalizedAt,
      linkedEventId: linkedEventId ?? this.linkedEventId,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      options: options ?? this.options,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Poll && other.pollId == pollId;
  }

  @override
  int get hashCode => pollId.hashCode;
}

/// 투표 옵션
class PollOption {
  const PollOption({
    required this.id,
    this.text,
    this.date,
    this.voteCount,
    this.votes,
  });

  final String id;
  final String? text;
  final DateTime? date;
  final int? voteCount;
  final List<String>? votes;

  PollOption copyWith({
    String? id,
    String? text,
    DateTime? date,
    int? voteCount,
    List<String>? votes,
  }) {
    return PollOption(
      id: id ?? this.id,
      text: text ?? this.text,
      date: date ?? this.date,
      voteCount: voteCount ?? this.voteCount,
      votes: votes ?? this.votes,
    );
  }
}

enum PollType {
  text,
  date,
  option;

  String get value {
    switch (this) {
      case PollType.text:
        return 'text';
      case PollType.date:
        return 'date';
      case PollType.option:
        return 'option';
    }
  }

  static PollType? fromString(String? value) {
    if (value == null) return null;
    switch (value) {
      case 'text':
        return PollType.text;
      case 'date':
        return PollType.date;
      case 'option':
        return PollType.option;
      default:
        return null;
    }
  }
}
