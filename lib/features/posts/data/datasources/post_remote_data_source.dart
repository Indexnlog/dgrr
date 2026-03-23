import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/errors/errors.dart';
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
        .handleError((error) {
          throw mapFirebaseException(
            error,
            fallbackMessage: '공지 목록을 불러오는 중 오류가 발생했습니다',
          );
        })
        .map(
          (snap) => snap.docs
              .map((doc) => PostModel.fromFirestore(doc.id, doc.data()))
              .toList(),
        );
  }

  /// 카테고리별 게시글
  Stream<List<PostModel>> watchPostsByCategory(String teamId, String category) {
    return _postsRef(teamId)
        .where('category', isEqualTo: category)
        .orderBy('createdAt', descending: true)
        .limit(20)
        .snapshots()
        .handleError((error) {
          throw mapFirebaseException(
            error,
            fallbackMessage: '카테고리 공지를 불러오는 중 오류가 발생했습니다',
          );
        })
        .map(
          (snap) => snap.docs
              .map((doc) => PostModel.fromFirestore(doc.id, doc.data()))
              .toList(),
        );
  }

  /// 공지 게시글 페이지 조회 (생성일 최신순)
  Future<
    ({
      List<PostModel> posts,
      QueryDocumentSnapshot<Map<String, dynamic>>? lastDoc,
      bool hasMore,
    })
  >
  fetchNoticePostsPage(
    String teamId, {
    QueryDocumentSnapshot<Map<String, dynamic>>? startAfter,
    int limit = 20,
  }) async {
    Query<Map<String, dynamic>> query = _postsRef(teamId)
        .where('category', isEqualTo: '공지')
        .orderBy('createdAt', descending: true)
        .limit(limit);

    if (startAfter != null) {
      query = query.startAfterDocument(startAfter);
    }

    try {
      final snap = await query.get();
      final docs = snap.docs;
      return (
        posts: docs
            .map((d) => PostModel.fromFirestore(d.id, d.data()))
            .toList(),
        lastDoc: docs.isNotEmpty ? docs.last : null,
        hasMore: docs.length == limit,
      );
    } catch (error) {
      throw mapFirebaseException(
        error,
        fallbackMessage: '공지 페이지를 불러오는 중 오류가 발생했습니다',
      );
    }
  }

  /// 단일 게시글 조회
  Stream<PostModel?> watchPost(String teamId, String postId) {
    return _postsRef(teamId)
        .doc(postId)
        .snapshots()
        .handleError((error) {
          throw mapFirebaseException(
            error,
            fallbackMessage: '공지 상세를 불러오는 중 오류가 발생했습니다',
          );
        })
        .map(
          (doc) =>
              doc.exists ? PostModel.fromFirestore(doc.id, doc.data()!) : null,
        );
  }

  /// 게시글 생성
  Future<String> createPost(String teamId, PostModel post) async {
    try {
      final doc = await _postsRef(teamId).add(post.toFirestore());
      return doc.id;
    } catch (error) {
      throw mapFirebaseException(error, fallbackMessage: '공지 등록 중 오류가 발생했습니다');
    }
  }

  /// 게시글 업데이트
  Future<void> updatePost(
    String teamId,
    String postId,
    Map<String, dynamic> data,
  ) async {
    try {
      await _postsRef(teamId).doc(postId).update(data);
    } catch (error) {
      throw mapFirebaseException(error, fallbackMessage: '공지 수정 중 오류가 발생했습니다');
    }
  }

  /// 게시글 삭제
  Future<void> deletePost(String teamId, String postId) async {
    try {
      await _postsRef(teamId).doc(postId).delete();
    } catch (error) {
      throw mapFirebaseException(error, fallbackMessage: '공지 삭제 중 오류가 발생했습니다');
    }
  }
}
