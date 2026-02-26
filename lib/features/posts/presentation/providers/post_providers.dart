import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../teams/presentation/providers/current_team_provider.dart';
import '../../data/datasources/post_remote_data_source.dart';
import '../../data/models/post_model.dart';

final postDataSourceProvider = Provider<PostRemoteDataSource>((ref) {
  return PostRemoteDataSource(firestore: FirebaseFirestore.instance);
});

/// 최근 게시글 (고정 우선)
final recentPostsProvider = StreamProvider<List<PostModel>>((ref) {
  final teamId = ref.watch(currentTeamIdProvider);
  if (teamId == null) return const Stream.empty();
  return ref.watch(postDataSourceProvider).watchRecentPosts(teamId);
});

/// 공지 게시글만
final noticePinnedPostsProvider = StreamProvider<List<PostModel>>((ref) {
  final teamId = ref.watch(currentTeamIdProvider);
  if (teamId == null) return const Stream.empty();
  return ref.watch(postDataSourceProvider).watchPostsByCategory(teamId, '공지');
});

/// 단일 게시글 (수정용)
final postDetailProvider =
    StreamProvider.family<PostModel?, String>((ref, postId) {
  final teamId = ref.watch(currentTeamIdProvider);
  if (teamId == null) return Stream.value(null);
  return ref.watch(postDataSourceProvider).watchPost(teamId, postId);
});
