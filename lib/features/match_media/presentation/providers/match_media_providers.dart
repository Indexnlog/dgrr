import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../teams/presentation/providers/current_team_provider.dart';
import '../../data/datasources/match_media_remote_data_source.dart';
import '../../data/models/match_media_model.dart';

final matchMediaDataSourceProvider = Provider<MatchMediaRemoteDataSource>((ref) {
  return MatchMediaRemoteDataSource(firestore: FirebaseFirestore.instance);
});

/// 경기별 영상 Provider (Stream)
final matchMediaProvider =
    StreamProvider.family<MatchMediaModel?, String>((ref, matchId) {
  final teamId = ref.watch(currentTeamIdProvider);
  if (teamId == null) return Stream.value(null);
  return ref
      .watch(matchMediaDataSourceProvider)
      .watchByMatchId(teamId, matchId);
});
