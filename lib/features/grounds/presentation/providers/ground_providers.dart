import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../teams/presentation/providers/current_team_provider.dart';
import '../../data/datasources/ground_remote_data_source.dart';
import '../../data/models/ground_model.dart';

final groundDataSourceProvider = Provider<GroundRemoteDataSource>((ref) {
  return GroundRemoteDataSource(firestore: FirebaseFirestore.instance);
});

final activeGroundsProvider = StreamProvider<List<GroundModel>>((ref) {
  final teamId = ref.watch(currentTeamIdProvider);
  if (teamId == null) return const Stream.empty();
  return ref.watch(groundDataSourceProvider).watchActiveGrounds(teamId);
});

/// 전체 구장 목록 (관리 페이지용)
final allGroundsProvider = StreamProvider<List<GroundModel>>((ref) {
  final teamId = ref.watch(currentTeamIdProvider);
  if (teamId == null) return const Stream.empty();
  return ref.watch(groundDataSourceProvider).watchAllGrounds(teamId);
});
