import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../teams/presentation/providers/current_team_provider.dart';
import '../../data/datasources/event_remote_data_source.dart';
import '../../data/models/event_model.dart';

/// EventRemoteDataSource Provider
final eventDataSourceProvider = Provider<EventRemoteDataSource>((ref) {
  return EventRemoteDataSource(firestore: FirebaseFirestore.instance);
});

/// 다가오는 수업 목록 실시간 스트림
final upcomingClassesProvider = StreamProvider<List<EventModel>>((ref) {
  final teamId = ref.watch(currentTeamIdProvider);
  if (teamId == null) return const Stream.empty();
  return ref.watch(eventDataSourceProvider).watchUpcomingClasses(teamId);
});

/// 월별 수업 목록 (캘린더용) - focusedMonth 기반
final monthlyClassesProvider =
    StreamProvider.family<List<EventModel>, ({int year, int month})>(
        (ref, param) {
  final teamId = ref.watch(currentTeamIdProvider);
  if (teamId == null) return const Stream.empty();

  final start = DateTime(param.year, param.month - 1, 25);
  final end = DateTime(param.year, param.month + 1, 7);
  final startStr =
      '${start.year}-${start.month.toString().padLeft(2, '0')}-${start.day.toString().padLeft(2, '0')}';
  final endStr =
      '${end.year}-${end.month.toString().padLeft(2, '0')}-${end.day.toString().padLeft(2, '0')}';

  return ref
      .watch(eventDataSourceProvider)
      .watchClassesInRange(teamId, startStr, endStr);
});

/// 최근 완료된 수업 목록 (출석 통계용)
final recentFinishedClassesProvider =
    StreamProvider<List<EventModel>>((ref) {
  final teamId = ref.watch(currentTeamIdProvider);
  if (teamId == null) return const Stream.empty();
  return ref
      .watch(eventDataSourceProvider)
      .watchRecentFinishedClasses(teamId);
});

/// 단일 수업 상세 스트림
final classDetailProvider =
    StreamProvider.family<EventModel?, String>((ref, eventId) {
  final teamId = ref.watch(currentTeamIdProvider);
  if (teamId == null) return Stream.value(null);
  return ref.watch(eventDataSourceProvider).watchClass(teamId, eventId);
});
