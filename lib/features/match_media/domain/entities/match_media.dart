/// 경기 영상 엔티티
class MatchMedia {
  const MatchMedia({
    required this.mediaId,
    required this.matchId,
    this.opponentTeamName,
    this.videoUrls,
    this.playlistUrl,
    this.uploadedBy,
    this.createdAt,
  });

  final String mediaId;
  final String matchId;
  final String? opponentTeamName;
  final List<String>? videoUrls;
  final String? playlistUrl;
  final String? uploadedBy;
  final DateTime? createdAt;

  MatchMedia copyWith({
    String? mediaId,
    String? matchId,
    String? opponentTeamName,
    List<String>? videoUrls,
    String? playlistUrl,
    String? uploadedBy,
    DateTime? createdAt,
  }) {
    return MatchMedia(
      mediaId: mediaId ?? this.mediaId,
      matchId: matchId ?? this.matchId,
      opponentTeamName: opponentTeamName ?? this.opponentTeamName,
      videoUrls: videoUrls ?? this.videoUrls,
      playlistUrl: playlistUrl ?? this.playlistUrl,
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
