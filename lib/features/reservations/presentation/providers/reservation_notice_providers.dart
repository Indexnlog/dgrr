import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_state_provider.dart';
import '../../../teams/presentation/providers/current_team_provider.dart';
import '../../data/datasources/reservation_notice_remote_data_source.dart';
import '../../data/models/reservation_notice_model.dart';

final reservationNoticeDataSourceProvider =
    Provider<ReservationNoticeRemoteDataSource>((ref) {
  return ReservationNoticeRemoteDataSource(firestore: FirebaseFirestore.instance);
});

/// 다가오는 예약 공지 목록
final upcomingReservationNoticesProvider =
    StreamProvider<List<ReservationNoticeModel>>((ref) {
  final teamId = ref.watch(currentTeamIdProvider);
  if (teamId == null) return const Stream.empty();
  return ref
      .watch(reservationNoticeDataSourceProvider)
      .watchUpcomingNotices(teamId);
});

/// 예약 공지 단건 (noticeId 파라미터)
final reservationNoticeDetailProvider =
    StreamProvider.family<ReservationNoticeModel?, String>((ref, noticeId) {
  final teamId = ref.watch(currentTeamIdProvider);
  if (teamId == null) return const Stream.empty();
  return ref
      .watch(reservationNoticeDataSourceProvider)
      .watchNotice(teamId, noticeId);
});

/// 현재 유저에게 배정된 예약 task만 포함한 공지 목록
final myReservationTasksProvider =
    StreamProvider<List<ReservationNoticeModel>>((ref) {
  final teamId = ref.watch(currentTeamIdProvider);
  final uid = ref.watch(currentUserProvider)?.uid;
  if (teamId == null || uid == null) return const Stream.empty();

  return ref
      .watch(reservationNoticeDataSourceProvider)
      .watchUpcomingNotices(teamId)
      .map((notices) => notices.where((n) {
            final slots = n.slots ?? [];
            return slots.any((s) =>
                s.managers != null && s.managers!.contains(uid));
          }).toList());
});
