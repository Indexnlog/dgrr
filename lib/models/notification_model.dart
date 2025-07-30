import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationModel {
  final String id;
  final String teamId;
  final String title;
  final String body;
  final String type; // 예: "eventReminder", "feeNotice", "general"
  final String targetUserId; // 푸시 수신 대상 UID
  final String? relatedId; // 관련 문서 ID (예: matchId, pollId 등)
  final bool isSent;
  final Timestamp scheduledAt; // 예약 전송 시각
  final Timestamp createdAt;
  final String createdBy;

  NotificationModel({
    required this.id,
    required this.teamId,
    required this.title,
    required this.body,
    required this.type,
    required this.targetUserId,
    this.relatedId,
    required this.isSent,
    required this.scheduledAt,
    required this.createdAt,
    required this.createdBy,
  });

  factory NotificationModel.fromDoc(dynamic doc) {
    final data = doc.data() as Map<String, dynamic>;
    return NotificationModel(
      id: doc.id,
      teamId: data['teamId'] ?? '',
      title: data['title'] ?? '',
      body: data['body'] ?? '',
      type: data['type'] ?? '',
      targetUserId: data['targetUserId'] ?? '',
      relatedId: data['relatedId'],
      isSent: data['isSent'] ?? false,
      scheduledAt: data['scheduledAt'] ?? Timestamp.now(),
      createdAt: data['createdAt'] ?? Timestamp.now(),
      createdBy: data['createdBy'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'teamId': teamId,
      'title': title,
      'body': body,
      'type': type,
      'targetUserId': targetUserId,
      'relatedId': relatedId,
      'isSent': isSent,
      'scheduledAt': scheduledAt,
      'createdAt': createdAt,
      'createdBy': createdBy,
    };
  }
}
