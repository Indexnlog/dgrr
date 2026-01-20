import '../../domain/entities/public_team.dart';

class PublicTeamModel extends PublicTeam {
  const PublicTeamModel({
    required super.id,
    required super.name,
    required super.logoUrl,
    required super.region,
    required super.intro,
  });

  factory PublicTeamModel.fromFirestore(String id, Map<String, dynamic> json) {
    return PublicTeamModel(
      id: id,
      name: (json['name'] as String?) ?? '',
      logoUrl: (json['logoUrl'] as String?) ?? '',
      region: (json['region'] as String?) ?? '',
      intro: (json['intro'] as String?) ?? '',
    );
  }
}
