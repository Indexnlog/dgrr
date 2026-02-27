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

/// 이번 달 시즌 ID (yyyy-MM)
String get currentSeasonId {
  final now = DateTime.now();
  return '${now.year}-${now.month.toString().padLeft(2, '0')}';
}

/// 월간 등록 투표 기간: 매월 20~24일 (.cursorrules)
bool get isWithinRegistrationVotePeriod {
  final day = DateTime.now().day;
  return day >= 20 && day <= 24;
}

/// 이번 달 월간 등록 현황 (총무 확인용)
final currentMonthRegistrationsProvider =
    StreamProvider<List<RegistrationModel>>((ref) {
  final teamId = ref.watch(currentTeamIdProvider);
  if (teamId == null) return const Stream.empty();
  return ref
      .watch(registrationDataSourceProvider)
      .watchRegistrations(teamId, currentSeasonId);
});
