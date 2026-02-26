import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/team.dart';

/// 팀 모델 (Firestore 변환 포함)
class TeamModel extends Team {
  const TeamModel({
    required super.teamId,
    required super.name,
    super.teamColor,
    super.teamLogoUrl,
    super.captainName,
    super.captainContact,
    super.memo,
    super.isOurTeam,
    super.createdAt,
  });

  factory TeamModel.fromFirestore(String id, Map<String, dynamic> json) {
    return TeamModel(
      teamId: id,
      name: json['name'] as String? ?? '',
      teamColor: json['teamColor'] as String?,
      teamLogoUrl: json['teamLogoUrl'] as String?,
      captainName: json['captainName'] as String?,
      captainContact: json['captainContact'] as String?,
      memo: json['memo'] as String?,
      isOurTeam: json['isOurTeam'] as bool?,
      createdAt: (json['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'teamId': teamId,
      'name': name,
      if (teamColor != null) 'teamColor': teamColor,
      if (teamLogoUrl != null) 'teamLogoUrl': teamLogoUrl,
      if (captainName != null) 'captainName': captainName,
      if (captainContact != null) 'captainContact': captainContact,
      if (memo != null) 'memo': memo,
      if (isOurTeam != null) 'isOurTeam': isOurTeam,
      if (createdAt != null) 'createdAt': Timestamp.fromDate(createdAt!),
    };
  }

  @override
  TeamModel copyWith({
    String? teamId,
    String? name,
    String? teamColor,
    String? teamLogoUrl,
    String? captainName,
    String? captainContact,
    String? memo,
    bool? isOurTeam,
    DateTime? createdAt,
  }) {
    return TeamModel(
      teamId: teamId ?? this.teamId,
      name: name ?? this.name,
      teamColor: teamColor ?? this.teamColor,
      teamLogoUrl: teamLogoUrl ?? this.teamLogoUrl,
      captainName: captainName ?? this.captainName,
      captainContact: captainContact ?? this.captainContact,
      memo: memo ?? this.memo,
      isOurTeam: isOurTeam ?? this.isOurTeam,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
