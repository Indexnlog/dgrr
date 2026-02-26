import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/record.dart';

/// 경기 기록 모델 팩토리 (Firestore 변환 포함)
class RecordModel {
  static Record fromFirestore(String id, Map<String, dynamic> json) {
    final type = RecordType.fromString(json['type'] as String?);
    final teamType = TeamType.fromString(json['teamType'] as String?);

    switch (type) {
      case RecordType.goal:
        return GoalRecordModel.fromFirestore(id, json, teamType ?? TeamType.our);
      case RecordType.substitution:
        return SubstitutionRecordModel.fromFirestore(
          id,
          json,
          teamType ?? TeamType.our,
        );
      default:
        throw UnsupportedError('Unsupported record type: $type');
    }
  }

  static Map<String, dynamic> toFirestore(Record record) {
    if (record is GoalRecord) {
      return GoalRecordModel.toFirestore(record);
    } else if (record is SubstitutionRecord) {
      return SubstitutionRecordModel.toFirestore(record);
    }
    throw UnsupportedError('Unsupported record type: ${record.runtimeType}');
  }
}

/// 골 기록 모델
class GoalRecordModel extends GoalRecord {
  const GoalRecordModel({
    required super.recordId,
    required super.teamType,
    required super.timeOffset,
    required super.timestamp,
    super.createdBy,
    super.playerId,
    super.playerName,
    super.playerNumber,
    super.assistPlayerId,
    super.assistPlayerName,
    super.goalType,
    super.isOwnGoal,
    super.scoreAfterGoal,
  });

  factory GoalRecordModel.fromFirestore(
    String id,
    Map<String, dynamic> json,
    TeamType teamType,
  ) {
    return GoalRecordModel(
      recordId: id,
      teamType: teamType,
      timeOffset: json['timeOffset'] as int? ?? 0,
      timestamp: (json['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      createdBy: json['createdBy'] as String?,
      playerId: json['playerId'] as String?,
      playerName: json['playerName'] as String?,
      playerNumber: json['playerNumber'] as int?,
      assistPlayerId: json['assistPlayerId'] as String?,
      assistPlayerName: json['assistPlayerName'] as String?,
      goalType: json['goalType'] as String?,
      isOwnGoal: json['isOwnGoal'] as bool?,
      scoreAfterGoal: json['scoreAfterGoal'] as int?,
    );
  }

  static Map<String, dynamic> toFirestore(GoalRecord record) {
    return {
      'type': record.type.value,
      'teamType': record.teamType.value,
      'timeOffset': record.timeOffset,
      'timestamp': Timestamp.fromDate(record.timestamp),
      if (record.createdBy != null) 'createdBy': record.createdBy,
      if (record.playerId != null) 'playerId': record.playerId,
      if (record.playerName != null) 'playerName': record.playerName,
      if (record.playerNumber != null) 'playerNumber': record.playerNumber,
      if (record.assistPlayerId != null) 'assistPlayerId': record.assistPlayerId,
      if (record.assistPlayerName != null)
        'assistPlayerName': record.assistPlayerName,
      if (record.goalType != null) 'goalType': record.goalType,
      if (record.isOwnGoal != null) 'isOwnGoal': record.isOwnGoal,
      if (record.scoreAfterGoal != null)
        'scoreAfterGoal': record.scoreAfterGoal,
    };
  }

  @override
  GoalRecordModel copyWith({
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
    return GoalRecordModel(
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

/// 교체 기록 모델
class SubstitutionRecordModel extends SubstitutionRecord {
  const SubstitutionRecordModel({
    required super.recordId,
    required super.teamType,
    required super.timeOffset,
    required super.timestamp,
    super.createdBy,
    super.inPlayerId,
    super.inPlayerName,
    super.inPlayerNumber,
    super.outPlayerId,
    super.outPlayerName,
    super.outPlayerNumber,
  });

  factory SubstitutionRecordModel.fromFirestore(
    String id,
    Map<String, dynamic> json,
    TeamType teamType,
  ) {
    return SubstitutionRecordModel(
      recordId: id,
      teamType: teamType,
      timeOffset: json['timeOffset'] as int? ?? 0,
      timestamp: (json['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      createdBy: json['createdBy'] as String?,
      inPlayerId: json['inPlayerId'] as String?,
      inPlayerName: json['inPlayerName'] as String?,
      inPlayerNumber: json['inPlayerNumber'] as int?,
      outPlayerId: json['outPlayerId'] as String?,
      outPlayerName: json['outPlayerName'] as String?,
      outPlayerNumber: json['outPlayerNumber'] as int?,
    );
  }

  static Map<String, dynamic> toFirestore(SubstitutionRecord record) {
    return {
      'type': record.type.value,
      'teamType': record.teamType.value,
      'timeOffset': record.timeOffset,
      'timestamp': Timestamp.fromDate(record.timestamp),
      if (record.createdBy != null) 'createdBy': record.createdBy,
      if (record.inPlayerId != null) 'inPlayerId': record.inPlayerId,
      if (record.inPlayerName != null) 'inPlayerName': record.inPlayerName,
      if (record.inPlayerNumber != null)
        'inPlayerNumber': record.inPlayerNumber,
      if (record.outPlayerId != null) 'outPlayerId': record.outPlayerId,
      if (record.outPlayerName != null) 'outPlayerName': record.outPlayerName,
      if (record.outPlayerNumber != null)
        'outPlayerNumber': record.outPlayerNumber,
    };
  }

  @override
  SubstitutionRecordModel copyWith({
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
    return SubstitutionRecordModel(
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
