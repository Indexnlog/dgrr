import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/notification_model.dart';

/// 알림 Firestore 데이터소스
class NotificationRemoteDataSource {
  NotificationRemoteDataSource({required this.firestore});

  final FirebaseFirestore firestore;

  CollectionReference<Map<String, dynamic>> _notificationsRef(String teamId) =>
      firestore.collection('teams').doc(teamId).collection('notifications');

  /// 팀 알림 목록 (최신순) - 클라이언트에서 toUserId/targetGroup 필터
  Stream<List<NotificationModel>> watchTeamNotifications(String teamId) {
    return _notificationsRef(teamId)
        .orderBy('createdAt', descending: true)
        .limit(100)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) =>
                NotificationModel.fromFirestore(doc.id, doc.data()))
            .toList());
  }

  /// 읽음 처리
  Future<void> markAsRead(
    String teamId,
    String notificationId,
    String userId,
  ) async {
    final ref = _notificationsRef(teamId).doc(notificationId);
    await firestore.runTransaction((tx) async {
      final snap = await tx.get(ref);
      if (!snap.exists) return;
      final data = snap.data()!;
      final readBy = List<String>.from(data['readBy'] ?? []);
      if (!readBy.contains(userId)) {
        readBy.add(userId);
        tx.update(ref, {'readBy': readBy});
      }
    });
  }
}
