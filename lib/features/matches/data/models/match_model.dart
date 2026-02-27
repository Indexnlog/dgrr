import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/match.dart';

/// 상대팀 정보 Firestore 변환
class OpponentInfoModel extends OpponentInfo {
  const OpponentInfoModel({
    super.teamId,
    super.name,
    super.contact,
    super.status,
  });

  factory OpponentInfoModel.fromMap(Map<String, dynamic> map) {
    return OpponentInfoModel(
      teamId: map['teamId'] as String?,
      name: map['name'] as String?,
      contact: map['contact'] as String?,
      status: map['status'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (teamId != null) 'teamId': teamId,
      if (name != null) 'name': name,
      if (contact != null) 'contact': contact,
      'status': status ?? 'seeking',
    };
  }
}

/// 경기 모델 (Firestore 변환 포함)
class MatchModel extends Match {
  const MatchModel({
    required super.matchId,
    super.matchType,
    super.date,
    super.startTime,
    super.endTime,
    super.location,
    super.status,
    super.gameStatus,
    super.minPlayers,
    super.isTimeConfirmed,
    super.opponent,
    super.registerStart,
    super.registerEnd,
    super.participants,
    super.attendees,
    super.absentees,
    super.lateAttendees,
    super.lateReasons,
    super.absenceReasons,
    super.ballBringers,
    super.lineup,
    super.lineupSize,
    super.captainId,
    super.lineupAnnouncedAt,
    super.createdBy,
    super.createdAt,
    super.updatedAt,
    super.teamName,
    super.recruitStatus,
  });

  factory MatchModel.fromFirestore(String id, Map<String, dynamic> json) {
    // opponent 객체 파싱 (없으면 teamName으로 폴백 생성)
    OpponentInfoModel? opponent;
    if (json['opponent'] is Map<String, dynamic>) {
      opponent = OpponentInfoModel.fromMap(
        json['opponent'] as Map<String, dynamic>,
      );
    } else if (json['teamName'] != null) {
      opponent = OpponentInfoModel(
        name: json['teamName'] as String?,
      );
    }

    return MatchModel(
      matchId: id,
      matchType: json['matchType'] as String? ?? 'regular',
      date: (json['date'] as Timestamp?)?.toDate(),
      startTime: json['startTime'] as String?,
      endTime: json['endTime'] as String?,
      location: json['location'] as String?,
      status: MatchStatus.fromString(json['status'] as String?),
      gameStatus: GameStatus.fromString(json['gameStatus'] as String?),
      minPlayers: json['minPlayers'] as int? ?? 7,
      isTimeConfirmed: json['isTimeConfirmed'] as bool? ?? false,
      opponent: opponent,
      registerStart: (json['registerStart'] as Timestamp?)?.toDate(),
      registerEnd: (json['registerEnd'] as Timestamp?)?.toDate(),
      participants: json['participants'] != null
          ? List<String>.from(json['participants'] as List)
          : null,
      attendees: json['attendees'] != null
          ? List<String>.from(json['attendees'] as List)
          : null,
      absentees: json['absentees'] != null
          ? List<String>.from(json['absentees'] as List)
          : null,
      lateAttendees: json['lateAttendees'] != null
          ? List<String>.from(json['lateAttendees'] as List)
          : null,
      lateReasons: json['lateReasons'] != null
          ? Map<String, String>.from(
              (json['lateReasons'] as Map).map((k, v) => MapEntry(k.toString(), v.toString())))
          : null,
      absenceReasons: json['absenceReasons'] != null
          ? Map<String, dynamic>.from(json['absenceReasons'] as Map)
          : null,
      ballBringers: json['ballBringers'] != null
          ? List<String>.from(json['ballBringers'] as List)
          : null,
      lineup: json['lineup'] != null
          ? List<String>.from(json['lineup'] as List)
          : null,
      lineupSize: json['lineupSize'] as int?,
      captainId: json['captainId'] as String?,
      lineupAnnouncedAt: (json['lineupAnnouncedAt'] as Timestamp?)?.toDate(),
      createdBy: json['createdBy'] as String?,
      createdAt: (json['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (json['updatedAt'] as Timestamp?)?.toDate(),
      // 하위 호환
      teamName: json['teamName'] as String?,
      recruitStatus:
          RecruitStatus.fromString(json['recruitStatus'] as String?),
    );
  }

  Map<String, dynamic> toFirestore() {
    final opponentModel = opponent is OpponentInfoModel
        ? (opponent! as OpponentInfoModel)
        : null;

    return {
      'matchType': matchType ?? 'regular',
      if (date != null) 'date': Timestamp.fromDate(date!),
      if (startTime != null) 'startTime': startTime,
      if (endTime != null) 'endTime': endTime,
      if (location != null) 'location': location,
      if (status != null) 'status': status!.value,
      if (gameStatus != null) 'gameStatus': gameStatus!.value,
      'minPlayers': minPlayers ?? 7,
      'isTimeConfirmed': isTimeConfirmed ?? false,
      if (opponentModel != null) 'opponent': opponentModel.toMap(),
      // 하위 호환: teamName도 함께 저장
      if (opponent?.name != null) 'teamName': opponent!.name,
      if (registerStart != null)
        'registerStart': Timestamp.fromDate(registerStart!),
      if (registerEnd != null)
        'registerEnd': Timestamp.fromDate(registerEnd!),
      if (participants != null) 'participants': participants,
      if (lineup != null) 'lineup': lineup,
      if (lineupSize != null) 'lineupSize': lineupSize,
      if (captainId != null) 'captainId': captainId,
      if (lineupAnnouncedAt != null) 'lineupAnnouncedAt': Timestamp.fromDate(lineupAnnouncedAt!),
      'attendees': attendees ?? [],
      'absentees': absentees ?? [],
      if (lateAttendees != null) 'lateAttendees': lateAttendees,
      if (lateReasons != null) 'lateReasons': lateReasons,
      if (absenceReasons != null) 'absenceReasons': absenceReasons,
      if (ballBringers != null) 'ballBringers': ballBringers,
      if (createdBy != null) 'createdBy': createdBy,
      if (createdAt != null) 'createdAt': Timestamp.fromDate(createdAt!),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}
