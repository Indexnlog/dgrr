import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/feedback.dart';

/// 피드백 모델 (Firestore 변환 포함)
class FeedbackModel extends Feedback {
  const FeedbackModel({
    required super.feedbackId,
    required super.userId,
    super.type,
    super.content,
    super.status,
    super.resolvedBy,
    super.resolvedAt,
    super.createdAt,
  });

  factory FeedbackModel.fromFirestore(String id, Map<String, dynamic> json) {
    return FeedbackModel(
      feedbackId: id,
      userId: json['userId'] as String? ?? '',
      type: json['type'] as String?,
      content: json['content'] as String?,
      status: FeedbackStatus.fromString(json['status'] as String?),
      resolvedBy: json['resolvedBy'] as String?,
      resolvedAt: (json['resolvedAt'] as Timestamp?)?.toDate(),
      createdAt: (json['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      if (type != null) 'type': type,
      if (content != null) 'content': content,
      if (status != null) 'status': status!.value,
      if (resolvedBy != null) 'resolvedBy': resolvedBy,
      if (resolvedAt != null) 'resolvedAt': Timestamp.fromDate(resolvedAt!),
      if (createdAt != null) 'createdAt': Timestamp.fromDate(createdAt!),
    };
  }
}
