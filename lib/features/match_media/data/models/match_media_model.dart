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
    super.timestampComments,
    super.uploadedBy,
    super.createdAt,
  });

  factory MatchMediaModel.fromFirestore(String id, Map<String, dynamic> json) {
    List<TimestampComment>? comments;
    if (json['timestampComments'] != null) {
      final list = json['timestampComments'] as List;
      comments = list.map((e) {
        final m = e as Map<String, dynamic>;
        return TimestampComment(
          timestamp: m['timestamp'] as String? ?? '',
          userId: m['userId'] as String? ?? '',
          userName: m['userName'] as String?,
          text: m['text'] as String? ?? '',
          createdAt: (m['createdAt'] as Timestamp?)?.toDate(),
        );
      }).toList();
    }

    return MatchMediaModel(
      mediaId: id,
      matchId: json['matchId'] as String? ?? id,
      opponentTeamName: json['opponentTeamName'] as String?,
      videoUrls: json['videoUrls'] != null
          ? List<String>.from(json['videoUrls'] as List)
          : null,
      playlistUrl: json['playlistUrl'] as String?,
      timestampComments: comments,
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
      if (timestampComments != null)
        'timestampComments': timestampComments!
            .map((c) => {
                  'timestamp': c.timestamp,
                  'userId': c.userId,
                  'userName': c.userName,
                  'text': c.text,
                  'createdAt': c.createdAt != null
                      ? Timestamp.fromDate(c.createdAt!)
                      : FieldValue.serverTimestamp(),
                })
            .toList(),
      if (uploadedBy != null) 'uploadedBy': uploadedBy,
      if (createdAt != null) 'createdAt': Timestamp.fromDate(createdAt!),
    };
  }
}
