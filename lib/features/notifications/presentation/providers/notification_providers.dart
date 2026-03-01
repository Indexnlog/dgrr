import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_state_provider.dart';
import '../../../teams/presentation/providers/current_team_provider.dart';
import '../../data/datasources/notification_remote_data_source.dart';
import '../../data/models/notification_model.dart';

/// NotificationRemoteDataSource Provider
final notificationDataSourceProvider =
    Provider<NotificationRemoteDataSource>((ref) {
  return NotificationRemoteDataSource(firestore: FirebaseFirestore.instance);
});

/// 내 알림 목록 (toUserId에 포함되거나 targetGroup이 allMembers인 것)
final myNotificationsProvider =
    StreamProvider.autoDispose<List<NotificationModel>>((ref) {
  final teamId = ref.watch(currentTeamIdProvider);
  final uid = ref.watch(currentUserProvider)?.uid;
  if (teamId == null || uid == null) return const Stream.empty();

  return ref.watch(notificationDataSourceProvider).watchTeamNotifications(teamId).map(
        (list) => list.where((n) {
          if (n.targetGroup == 'allMembers') return true;
          return n.toUserId?.contains(uid) ?? false;
        }).toList(),
      );
});

/// 읽지 않은 알림 개수 (배지용)
final unreadNotificationCountProvider = Provider.autoDispose<int>((ref) {
  final async = ref.watch(myNotificationsProvider);
  final uid = ref.watch(currentUserProvider)?.uid;
  if (uid == null) return 0;
  return async.when(
    data: (list) =>
        list.where((n) => !(n.readBy?.contains(uid) ?? false)).length,
    loading: () => 0,
    error: (_, __) => 0,
  );
});
