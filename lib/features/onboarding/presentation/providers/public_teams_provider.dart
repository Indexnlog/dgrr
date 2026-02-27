import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/providers/firebase_ready_provider.dart';
import '../../../teams/presentation/providers/user_teams_provider.dart';
import '../../data/models/public_team_model.dart';
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

/// 로그인한 사용자가 속한 팀 목록 (status: active)
/// teams_public + teams에서 팀 정보 조회
final userTeamsAsPublicProvider = FutureProvider<List<PublicTeam>>((ref) async {
  final teamIds = await ref.watch(userTeamsProvider.future);
  if (teamIds.isEmpty) return [];

  final firestore = FirebaseFirestore.instance;
  final results = <PublicTeam>[];

  for (final id in teamIds) {
    var doc = await firestore.collection('teams_public').doc(id).get();
    if (doc.exists) {
      results.add(PublicTeamModel.fromFirestore(doc.id, doc.data()!));
    } else {
      doc = await firestore.collection('teams').doc(id).get();
      if (doc.exists) {
        final d = doc.data() ?? {};
        results.add(PublicTeamModel(
          id: id,
          name: d['name'] as String? ?? id,
          logoUrl: '',
          region: '',
          intro: '',
        ));
      }
    }
  }
  return results;
});
