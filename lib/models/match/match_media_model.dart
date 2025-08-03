import 'package:cloud_firestore/cloud_firestore.dart';

class MatchMediaModel {
  final String id;
  final String teamId;
  final String matchId;
  final String opponentTeamName;
  final String playlistUrl;
  final List<MatchVideo> videoUrls;
  final String uploadedBy;
  final Timestamp createdAt;

  MatchMediaModel({
    required this.id,
    required this.teamId,
    required this.matchId,
    required this.opponentTeamName,
    required this.playlistUrl,
    required this.videoUrls,
    required this.uploadedBy,
    required this.createdAt,
  });

  factory MatchMediaModel.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return MatchMediaModel(
      id: doc.id,
      teamId: data['teamId'] ?? '',
      matchId: data['matchId'] ?? '',
      opponentTeamName: data['opponentTeamName'] ?? '',
      playlistUrl: data['playlistUrl'] ?? '',
      videoUrls: (data['videoUrls'] as List<dynamic>? ?? [])
          .map((e) => MatchVideo.fromMap(e))
          .toList(),
      uploadedBy: data['uploadedBy'] ?? '',
      createdAt: data['createdAt'] ?? Timestamp.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'teamId': teamId,
      'matchId': matchId,
      'opponentTeamName': opponentTeamName,
      'playlistUrl': playlistUrl,
      'videoUrls': videoUrls.map((e) => e.toMap()).toList(),
      'uploadedBy': uploadedBy,
      'createdAt': createdAt,
    };
  }
}

class MatchVideo {
  final String title;
  final String url;

  MatchVideo({required this.title, required this.url});

  factory MatchVideo.fromMap(Map<String, dynamic> map) {
    return MatchVideo(title: map['title'] ?? '', url: map['url'] ?? '');
  }

  Map<String, dynamic> toMap() {
    return {'title': title, 'url': url};
  }
}
