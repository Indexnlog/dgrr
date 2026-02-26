/// 피드백 엔티티
class Feedback {
  const Feedback({
    required this.feedbackId,
    required this.userId,
    this.type,
    this.content,
    this.status,
    this.resolvedBy,
    this.resolvedAt,
    this.createdAt,
  });

  final String feedbackId;
  final String userId;
  final String? type;
  final String? content;
  final FeedbackStatus? status;
  final String? resolvedBy;
  final DateTime? resolvedAt;
  final DateTime? createdAt;

  Feedback copyWith({
    String? feedbackId,
    String? userId,
    String? type,
    String? content,
    FeedbackStatus? status,
    String? resolvedBy,
    DateTime? resolvedAt,
    DateTime? createdAt,
  }) {
    return Feedback(
      feedbackId: feedbackId ?? this.feedbackId,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      content: content ?? this.content,
      status: status ?? this.status,
      resolvedBy: resolvedBy ?? this.resolvedBy,
      resolvedAt: resolvedAt ?? this.resolvedAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Feedback && other.feedbackId == feedbackId;
  }

  @override
  int get hashCode => feedbackId.hashCode;
}

enum FeedbackStatus {
  new_,
  resolved,
  rejected;

  String get value {
    switch (this) {
      case FeedbackStatus.new_:
        return 'new';
      case FeedbackStatus.resolved:
        return 'resolved';
      case FeedbackStatus.rejected:
        return 'rejected';
    }
  }

  static FeedbackStatus? fromString(String? value) {
    if (value == null) return null;
    switch (value) {
      case 'new':
        return FeedbackStatus.new_;
      case 'resolved':
        return FeedbackStatus.resolved;
      case 'rejected':
        return FeedbackStatus.rejected;
      default:
        return null;
    }
  }
}
