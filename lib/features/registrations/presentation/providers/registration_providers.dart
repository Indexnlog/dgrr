import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../teams/presentation/providers/current_team_provider.dart';
import '../../data/datasources/registration_remote_data_source.dart';
import '../../data/models/registration_model.dart';

final registrationDataSourceProvider =
    Provider<RegistrationRemoteDataSource>((ref) {
  return RegistrationRemoteDataSource(firestore: FirebaseFirestore.instance);
});

/// 특정 시즌 등록 목록
final seasonRegistrationsProvider =
    StreamProvider.family<List<RegistrationModel>, String>(
        (ref, eventId) {
  final teamId = ref.watch(currentTeamIdProvider);
  if (teamId == null) return const Stream.empty();
  return ref
      .watch(registrationDataSourceProvider)
      .watchRegistrations(teamId, eventId);
});

/// 내 최근 등록 이력
final myRegistrationsProvider =
    StreamProvider.family<List<RegistrationModel>, String>(
        (ref, userId) {
  final teamId = ref.watch(currentTeamIdProvider);
  if (teamId == null) return const Stream.empty();
  return ref
      .watch(registrationDataSourceProvider)
      .watchMyRegistrations(teamId, userId);
});
