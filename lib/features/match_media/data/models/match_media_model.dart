import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/match_media.dart';

/// 경기 영상 모델 (Firestore 변환 포함)
class MatchMediaModel extends MatchMedia {
  const MatchMediaModel({
    required super.mediaId,
    required super.matchId,
    super.opponentTeamName,
    super.videoUrls,
    super.playlistUrl,
    super.uploadedBy,
    super.createdAt,
  });

  factory MatchMediaModel.fromFirestore(String id, Map<String, dynamic> json) {
    return MatchMediaModel(
      mediaId: id,
      matchId: json['matchId'] as String? ?? '',
      opponentTeamName: json['opponentTeamName'] as String?,
      videoUrls: json['videoUrls'] != null
          ? List<String>.from(json['videoUrls'] as List)
          : null,
      playlistUrl: json['playlistUrl'] as String?,
      uploadedBy: json['uploadedBy'] as String?,
      createdAt: (json['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'matchId': matchId,
      if (opponentTeamName != null) 'opponentTeamName': opponentTeamName,
      if (videoUrls != null) 'videoUrls': videoUrls,
      if (playlistUrl != null) 'playlistUrl': playlistUrl,
      if (uploadedBy != null) 'uploadedBy': uploadedBy,
      if (createdAt != null) 'createdAt': Timestamp.fromDate(createdAt!),
    };
  }
}
