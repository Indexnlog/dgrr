import 'package:cloud_firestore/cloud_firestore.dart';

class TeamModel {
  final String id;
  final String name;
  final String logoUrl; // 팀 로고 이미지
  final String colorHex; // 테마 색상 (예: "#1D4ED8")
  final String intro; // 소개 문구
  final String managerId; // 팀 대표 또는 관리자 UID
  final Timestamp createdAt;

  TeamModel({
    required this.id,
    required this.name,
    required this.logoUrl,
    required this.colorHex,
    required this.intro,
    required this.managerId,
    required this.createdAt,
  });

  factory TeamModel.fromDoc(dynamic doc) {
    final data = doc.data() as Map<String, dynamic>;
    return TeamModel(
      id: doc.id,
      name: data['name'] ?? '',
      logoUrl: data['logoUrl'] ?? '',
      colorHex: data['colorHex'] ?? '#000000',
      intro: data['intro'] ?? '',
      managerId: data['managerId'] ?? '',
      createdAt: data['createdAt'] ?? Timestamp.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'logoUrl': logoUrl,
      'colorHex': colorHex,
      'intro': intro,
      'managerId': managerId,
      'createdAt': createdAt,
    };
  }
}
