import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../teams/presentation/providers/current_team_provider.dart';
import '../../data/datasources/poll_remote_data_source.dart';
import '../../data/models/poll_model.dart';

/// PollRemoteDataSource Provider
final pollDataSourceProvider = Provider<PollRemoteDataSource>((ref) {
  return PollRemoteDataSource(firestore: FirebaseFirestore.instance);
});

/// 활성 투표 목록
final activePollsProvider = StreamProvider<List<PollModel>>((ref) {
  final teamId = ref.watch(currentTeamIdProvider);
  if (teamId == null) return const Stream.empty();
  return ref.watch(pollDataSourceProvider).watchActivePolls(teamId);
});

/// 전체 투표 목록 (최근순)
final allPollsProvider = StreamProvider<List<PollModel>>((ref) {
  final teamId = ref.watch(currentTeamIdProvider);
  if (teamId == null) return const Stream.empty();
  return ref.watch(pollDataSourceProvider).watchAllPolls(teamId);
});

/// 단일 투표 상세
final pollDetailProvider =
    StreamProvider.family<PollModel?, String>((ref, pollId) {
  final teamId = ref.watch(currentTeamIdProvider);
  if (teamId == null) return Stream.value(null);
  return ref.watch(pollDataSourceProvider).watchPoll(teamId, pollId);
});
