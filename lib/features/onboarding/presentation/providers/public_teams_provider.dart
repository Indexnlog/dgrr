import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/providers/firebase_ready_provider.dart';
import '../../data/datasources/teams_public_remote_data_source.dart';
import '../../data/repositories/teams_public_repository_impl.dart';
import '../../domain/entities/public_team.dart';
import '../../domain/repositories/teams_public_repository.dart';
import '../../domain/usecases/watch_public_teams.dart';

final teamsPublicRepositoryProvider = Provider<TeamsPublicRepository>((ref) {
  final firebaseReady = ref.watch(firebaseReadyProvider);
  if (!firebaseReady) {
    return TeamsPublicMockRepository();
  }

  final firestore = FirebaseFirestore.instance;
  final remoteDataSource = TeamsPublicRemoteDataSource(firestore);
  return TeamsPublicRepositoryImpl(remoteDataSource);
});

final watchPublicTeamsProvider = Provider<WatchPublicTeams>((ref) {
  return WatchPublicTeams(ref.watch(teamsPublicRepositoryProvider));
});

final publicTeamsStreamProvider = StreamProvider<List<PublicTeam>>((ref) {
  return ref.watch(watchPublicTeamsProvider).call();
});
