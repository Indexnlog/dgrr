import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/notification.dart';

/// 알림 모델 (Firestore 변환 포함)
class NotificationModel extends Notification {
  const NotificationModel({
    required super.notificationId,
    required super.title,
    super.message,
    super.type,
    super.relatedId,
    super.toUserId,
    super.readBy,
    super.targetGroup,
    super.isSent,
    super.sendAt,
    super.createdAt,
  });

  factory NotificationModel.fromFirestore(
    String id,
    Map<String, dynamic> json,
  ) {
    return NotificationModel(
      notificationId: id,
      title: json['title'] as String? ?? '',
      message: json['message'] as String?,
      type: json['type'] as String?,
      relatedId: json['relatedId'] as String?,
      toUserId: json['toUserId'] != null
          ? List<String>.from(json['toUserId'] as List)
          : null,
      readBy: json['readBy'] != null
          ? List<String>.from(json['readBy'] as List)
          : null,
      targetGroup: json['targetGroup'] as String?,
      isSent: json['isSent'] as bool?,
      sendAt: (json['sendAt'] as Timestamp?)?.toDate(),
      createdAt: (json['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      if (message != null) 'message': message,
      if (type != null) 'type': type,
      if (relatedId != null) 'relatedId': relatedId,
      if (toUserId != null) 'toUserId': toUserId,
      if (readBy != null) 'readBy': readBy,
      if (targetGroup != null) 'targetGroup': targetGroup,
      if (isSent != null) 'isSent': isSent,
      if (sendAt != null) 'sendAt': Timestamp.fromDate(sendAt!),
      if (createdAt != null) 'createdAt': Timestamp.fromDate(createdAt!),
    };
  }
}
