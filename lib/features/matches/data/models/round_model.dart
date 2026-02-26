import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/round.dart';

/// 라운드 모델 (Firestore 변환 포함)
class RoundModel extends Round {
  const RoundModel({
    required super.roundId,
    super.roundIndex,
    super.status,
    super.startTime,
    super.endTime,
    super.ourScore,
    super.oppScore,
    super.createdAt,
    super.createdBy,
  });

  factory RoundModel.fromFirestore(String id, Map<String, dynamic> json) {
    final scoreMap = json['score'] as Map<String, dynamic>?;
    final our = scoreMap?['our'] as int?;
    final opp = scoreMap?['opp'] as int?;
    return RoundModel(
      roundId: id,
      roundIndex: json['roundIndex'] as int?,
      status: RoundStatus.fromString(json['status'] as String?),
      startTime: (json['startTime'] as Timestamp?)?.toDate(),
      endTime: (json['endTime'] as Timestamp?)?.toDate(),
      ourScore: our ?? 0,
      oppScore: opp ?? 0,
      createdAt: (json['createdAt'] as Timestamp?)?.toDate(),
      createdBy: json['createdBy'] as String?,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      if (roundIndex != null) 'roundIndex': roundIndex,
      if (status != null) 'status': status!.value,
      if (startTime != null) 'startTime': Timestamp.fromDate(startTime!),
      if (endTime != null) 'endTime': Timestamp.fromDate(endTime!),
      if (createdAt != null) 'createdAt': Timestamp.fromDate(createdAt!),
      if (createdBy != null) 'createdBy': createdBy,
    };
  }

  @override
  RoundModel copyWith({
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
    return RoundModel(
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
}
