import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/team_repository_impl.dart';
import '../../domain/repositories/team_repository.dart';
import '../../domain/usecases/request_join_team.dart';

final teamRepositoryProvider = Provider<TeamRepository>((ref) {
  return TeamRepositoryImpl(
    FirebaseFirestore.instance,
    FirebaseAuth.instance,
  );
});

final requestJoinTeamProvider = Provider<RequestJoinTeam>((ref) {
  return RequestJoinTeam(ref.watch(teamRepositoryProvider));
});
