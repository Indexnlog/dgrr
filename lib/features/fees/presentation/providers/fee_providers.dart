import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../teams/presentation/providers/current_team_provider.dart';
import '../../data/datasources/fee_remote_data_source.dart';
import '../../data/models/fee_model.dart';

final feeDataSourceProvider = Provider<FeeRemoteDataSource>((ref) {
  return FeeRemoteDataSource(firestore: FirebaseFirestore.instance);
});

final activeFeesProvider = StreamProvider<List<FeeModel>>((ref) {
  final teamId = ref.watch(currentTeamIdProvider);
  if (teamId == null) return const Stream.empty();
  return ref.watch(feeDataSourceProvider).watchActiveFees(teamId);
});

final allFeesProvider = StreamProvider<List<FeeModel>>((ref) {
  final teamId = ref.watch(currentTeamIdProvider);
  if (teamId == null) return const Stream.empty();
  return ref.watch(feeDataSourceProvider).watchAllFees(teamId);
});
