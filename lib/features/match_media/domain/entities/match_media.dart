/// 타임스탬프 댓글 (영상 특정 시점 + 코멘트)
class TimestampComment {
  const TimestampComment({
    required this.timestamp,
    required this.userId,
    this.userName,
    required this.text,
    this.createdAt,
  });

  /// "12:34" 형식 (분:초)
  final String timestamp;
  final String userId;
  final String? userName;
  final String text;
  final DateTime? createdAt;

  /// YouTube URL에 추가할 t 파라미터 (초)
  int get seconds {
    final parts = timestamp.split(':');
    if (parts.length >= 2) {
      final m = int.tryParse(parts[0]) ?? 0;
      final s = int.tryParse(parts[1]) ?? 0;
      return m * 60 + s;
    }
    return 0;
  }
}

/// 경기 영상 엔티티 (YouTube 링크만, 직접 저장 X)
class MatchMedia {
  const MatchMedia({
    required this.mediaId,
    required this.matchId,
    this.opponentTeamName,
    this.videoUrls,
    this.playlistUrl,
    this.timestampComments,
    this.uploadedBy,
    this.createdAt,
  });

  final String mediaId;
  final String matchId;
  final String? opponentTeamName;
  final List<String>? videoUrls;
  final String? playlistUrl;
  final List<TimestampComment>? timestampComments;
  final String? uploadedBy;
  final DateTime? createdAt;

  MatchMedia copyWith({
    String? mediaId,
    String? matchId,
    String? opponentTeamName,
    List<String>? videoUrls,
    String? playlistUrl,
    List<TimestampComment>? timestampComments,
    String? uploadedBy,
    DateTime? createdAt,
  }) {
    return MatchMedia(
      mediaId: mediaId ?? this.mediaId,
      matchId: matchId ?? this.matchId,
      opponentTeamName: opponentTeamName ?? this.opponentTeamName,
      videoUrls: videoUrls ?? this.videoUrls,
      playlistUrl: playlistUrl ?? this.playlistUrl,
      timestampComments: timestampComments ?? this.timestampComments,
      uploadedBy: uploadedBy ?? this.uploadedBy,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MatchMedia && other.mediaId == mediaId;
  }

  @override
  int get hashCode => mediaId.hashCode;
}
