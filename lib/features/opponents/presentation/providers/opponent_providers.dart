import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../teams/presentation/providers/current_team_provider.dart';
import '../../data/datasources/opponent_remote_data_source.dart';
import '../../data/models/opponent_model.dart';

final opponentDataSourceProvider = Provider<OpponentRemoteDataSource>((ref) {
  return OpponentRemoteDataSource(firestore: FirebaseFirestore.instance);
});

/// 상대팀 목록 스트림
final opponentsProvider = StreamProvider<List<OpponentModel>>((ref) {
  final teamId = ref.watch(currentTeamIdProvider);
  if (teamId == null) return Stream.value([]);

  return ref.watch(opponentDataSourceProvider).watchOpponents(teamId);
});
