import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/post_model.dart';

/// 게시글 Firestore 데이터소스
class PostRemoteDataSource {
  PostRemoteDataSource({required this.firestore});

  final FirebaseFirestore firestore;

  CollectionReference<Map<String, dynamic>> _postsRef(String teamId) =>
      firestore.collection('teams').doc(teamId).collection('posts');

  /// 최근 게시글 목록 (고정 우선, 최신순)
  Stream<List<PostModel>> watchRecentPosts(String teamId, {int limit = 20}) {
    return _postsRef(teamId)
        .orderBy('isPinned', descending: true)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => PostModel.fromFirestore(doc.id, doc.data()))
            .toList());
  }

  /// 카테고리별 게시글
  Stream<List<PostModel>> watchPostsByCategory(
    String teamId,
    String category,
  ) {
    return _postsRef(teamId)
        .where('category', isEqualTo: category)
        .orderBy('createdAt', descending: true)
        .limit(20)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => PostModel.fromFirestore(doc.id, doc.data()))
            .toList());
  }

  /// 단일 게시글 조회
  Stream<PostModel?> watchPost(String teamId, String postId) {
    return _postsRef(teamId)
        .doc(postId)
        .snapshots()
        .map((doc) => doc.exists
            ? PostModel.fromFirestore(doc.id, doc.data()!)
            : null);
  }

  /// 게시글 생성
  Future<String> createPost(String teamId, PostModel post) async {
    final doc = await _postsRef(teamId).add(post.toFirestore());
    return doc.id;
  }

  /// 게시글 업데이트
  Future<void> updatePost(
    String teamId,
    String postId,
    Map<String, dynamic> data,
  ) async {
    await _postsRef(teamId).doc(postId).update(data);
  }

  /// 게시글 삭제
  Future<void> deletePost(String teamId, String postId) async {
    await _postsRef(teamId).doc(postId).delete();
  }
}
