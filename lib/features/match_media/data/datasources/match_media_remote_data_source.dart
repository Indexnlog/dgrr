import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/match_media.dart';
import '../models/match_media_model.dart';

/// 경기 영상 Firestore 데이터소스 (YouTube 링크만 저장)
class MatchMediaRemoteDataSource {
  MatchMediaRemoteDataSource({required this.firestore});

  final FirebaseFirestore firestore;

  CollectionReference<Map<String, dynamic>> _ref(String teamId) =>
      firestore.collection('teams').doc(teamId).collection('match_media');

  /// 경기별 영상 조회 (matchId를 doc id로 사용)
  Stream<MatchMediaModel?> watchByMatchId(String teamId, String matchId) {
    return _ref(teamId).doc(matchId).snapshots().map((snap) {
      if (!snap.exists) return null;
      return MatchMediaModel.fromFirestore(matchId, snap.data()!);
    });
  }

  /// 영상 등록/수정 (matchId를 doc id로 사용, 1경기 1영상)
  Future<void> upsert(String teamId, MatchMediaModel media) async {
    final data = media.toFirestore();
    await _ref(teamId).doc(media.matchId).set(data, SetOptions(merge: true));
  }

  /// 타임스탬프 댓글 추가
  Future<void> addTimestampComment(
    String teamId,
    String mediaId,
    TimestampComment comment,
  ) async {
    final ref = _ref(teamId).doc(mediaId);
    final snap = await ref.get();
    if (!snap.exists) return;

    final list = (snap.data()?['timestampComments'] as List?) ?? [];
    list.add({
      'timestamp': comment.timestamp,
      'userId': comment.userId,
      'userName': comment.userName,
      'text': comment.text,
      'createdAt': FieldValue.serverTimestamp(),
    });
    await ref.update({
      'timestampComments': list,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
