import 'package:cloud_firestore/cloud_firestore.dart';

class FeedbackModel {
  final String id;
  final String teamId; // ✅ 추가됨
  final String content;
  final String type; // 운영 관련, 기능 요청 등
  final String userId;
  final Timestamp createdAt;
  final String status; // new, inProgress, resolved
  final String? resolvedBy;
  final Timestamp? resolvedAt;

  FeedbackModel({
    required this.id,
    required this.teamId,
    required this.content,
    required this.type,
    required this.userId,
    required this.createdAt,
    required this.status,
    this.resolvedBy,
    this.resolvedAt,
  });

  factory FeedbackModel.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return FeedbackModel(
      id: doc.id,
      teamId: data['teamId'] ?? '',
      content: data['content'] ?? '',
      type: data['type'] ?? '',
      userId: data['userId'] ?? '',
      createdAt: data['createdAt'] ?? Timestamp.now(),
      status: data['status'] ?? 'new',
      resolvedBy: data['resolvedBy'],
      resolvedAt: data['resolvedAt'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'teamId': teamId,
      'content': content,
      'type': type,
      'userId': userId,
      'createdAt': createdAt,
      'status': status,
      'resolvedBy': resolvedBy,
      'resolvedAt': resolvedAt,
    };
  }
}
