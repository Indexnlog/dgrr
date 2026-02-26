import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/poll.dart';

/// 투표 모델 (Firestore 변환 포함)
class PollModel extends Poll {
  const PollModel({
    required super.pollId,
    required super.title,
    super.description,
    super.type,
    super.category,
    super.targetMonth,
    super.anonymous,
    super.canChangeVote,
    super.maxSelections,
    super.showResultBeforeDeadline,
    super.isActive,
    super.expiresAt,
    super.resultFinalizedAt,
    super.linkedEventId,
    super.createdBy,
    super.createdAt,
    super.options,
  });

  factory PollModel.fromFirestore(String id, Map<String, dynamic> json) {
    return PollModel(
      pollId: id,
      title: json['title'] as String? ?? '',
      description: json['description'] as String?,
      type: PollType.fromString(json['type'] as String?),
      category: PollCategory.fromString(json['category'] as String?),
      targetMonth: json['targetMonth'] as String?,
      anonymous: json['anonymous'] as bool?,
      canChangeVote: json['canChangeVote'] as bool?,
      maxSelections: json['maxSelections'] as int?,
      showResultBeforeDeadline: json['showResultBeforeDeadline'] as bool?,
      isActive: json['isActive'] as bool?,
      expiresAt: (json['expiresAt'] as Timestamp?)?.toDate(),
      resultFinalizedAt: (json['resultFinalizedAt'] as Timestamp?)?.toDate(),
      linkedEventId: json['linkedEventId'] as String?,
      createdBy: json['createdBy'] as String?,
      createdAt: (json['createdAt'] as Timestamp?)?.toDate(),
      options: json['options'] != null
          ? (json['options'] as List)
              .map((e) => PollOptionModel.fromMap(e as Map<String, dynamic>))
              .toList()
          : null,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      if (description != null) 'description': description,
      if (type != null) 'type': type!.value,
      if (category != null) 'category': category!.value,
      if (targetMonth != null) 'targetMonth': targetMonth,
      if (anonymous != null) 'anonymous': anonymous,
      if (canChangeVote != null) 'canChangeVote': canChangeVote,
      if (maxSelections != null) 'maxSelections': maxSelections,
      if (showResultBeforeDeadline != null)
        'showResultBeforeDeadline': showResultBeforeDeadline,
      if (isActive != null) 'isActive': isActive,
      if (expiresAt != null) 'expiresAt': Timestamp.fromDate(expiresAt!),
      if (resultFinalizedAt != null)
        'resultFinalizedAt': Timestamp.fromDate(resultFinalizedAt!),
      if (linkedEventId != null) 'linkedEventId': linkedEventId,
      if (createdBy != null) 'createdBy': createdBy,
      if (createdAt != null) 'createdAt': Timestamp.fromDate(createdAt!),
      if (options != null)
        'options': options!.map((e) => PollOptionModel.toMap(e)).toList(),
    };
  }
}

/// 투표 옵션 모델
class PollOptionModel extends PollOption {
  const PollOptionModel({
    required super.id,
    super.text,
    super.date,
    super.voteCount,
    super.votes,
  });

  factory PollOptionModel.fromMap(Map<String, dynamic> json) {
    return PollOptionModel(
      id: json['id'] as String? ?? '',
      text: json['text'] as String?,
      date: (json['date'] as Timestamp?)?.toDate(),
      voteCount: json['voteCount'] as int?,
      votes: json['votes'] != null
          ? List<String>.from(json['votes'] as List)
          : null,
    );
  }

  static Map<String, dynamic> toMap(PollOption option) {
    return {
      'id': option.id,
      if (option.text != null) 'text': option.text,
      if (option.date != null) 'date': Timestamp.fromDate(option.date!),
      if (option.voteCount != null) 'voteCount': option.voteCount,
      if (option.votes != null) 'votes': option.votes,
    };
  }
}
