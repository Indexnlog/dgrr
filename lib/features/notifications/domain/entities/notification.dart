/// 알림 엔티티
class Notification {
  const Notification({
    required this.notificationId,
    required this.title,
    this.message,
    this.type,
    this.relatedId,
    this.toUserId,
    this.isSent,
    this.sendAt,
    this.createdAt,
  });

  final String notificationId;
  final String title;
  final String? message;
  final String? type;
  final String? relatedId;
  final List<String>? toUserId;
  final bool? isSent;
  final DateTime? sendAt;
  final DateTime? createdAt;

  Notification copyWith({
    String? notificationId,
    String? title,
    String? message,
    String? type,
    String? relatedId,
    List<String>? toUserId,
    bool? isSent,
    DateTime? sendAt,
    DateTime? createdAt,
  }) {
    return Notification(
      notificationId: notificationId ?? this.notificationId,
      title: title ?? this.title,
      message: message ?? this.message,
      type: type ?? this.type,
      relatedId: relatedId ?? this.relatedId,
      toUserId: toUserId ?? this.toUserId,
      isSent: isSent ?? this.isSent,
      sendAt: sendAt ?? this.sendAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Notification && other.notificationId == notificationId;
  }

  @override
  int get hashCode => notificationId.hashCode;
}
