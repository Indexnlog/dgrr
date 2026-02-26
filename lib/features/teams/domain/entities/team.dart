/// 팀 기본 정보 엔티티
class Team {
  const Team({
    required this.teamId,
    required this.name,
    this.teamColor,
    this.teamLogoUrl,
    this.captainName,
    this.captainContact,
    this.memo,
    this.isOurTeam,
    this.createdAt,
  });

  final String teamId;
  final String name;
  final String? teamColor;
  final String? teamLogoUrl;
  final String? captainName;
  final String? captainContact;
  final String? memo;
  final bool? isOurTeam;
  final DateTime? createdAt;

  Team copyWith({
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
    return Team(
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

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Team && other.teamId == teamId;
  }

  @override
  int get hashCode => teamId.hashCode;
}
