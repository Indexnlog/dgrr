/// 예약 공지 엔티티 (구장 예약 안내 및 성공 보고)
class ReservationNotice {
  const ReservationNotice({
    required this.noticeId,
    required this.targetDate,
    this.targetStartTime,
    this.targetEndTime,
    this.reservedForType,
    this.reservedForId,
    this.venueType,
    this.openAt,
    this.slots,
    this.fallback,
    this.status,
    this.createdBy,
    this.publishedAt,
    this.createdAt,
  });

  final String noticeId;
  final DateTime targetDate;
  final String? targetStartTime;
  final String? targetEndTime;
  final ReservationNoticeForType? reservedForType;
  final String? reservedForId;
  final VenueType? venueType;
  final DateTime? openAt;
  final List<ReservationNoticeSlot>? slots;
  final ReservationNoticeFallback? fallback;
  final ReservationNoticeStatus? status;
  final String? createdBy;
  final DateTime? publishedAt;
  final DateTime? createdAt;

  ReservationNotice copyWith({
    String? noticeId,
    DateTime? targetDate,
    String? targetStartTime,
    String? targetEndTime,
    ReservationNoticeForType? reservedForType,
    String? reservedForId,
    VenueType? venueType,
    DateTime? openAt,
    List<ReservationNoticeSlot>? slots,
    ReservationNoticeFallback? fallback,
    ReservationNoticeStatus? status,
    String? createdBy,
    DateTime? publishedAt,
    DateTime? createdAt,
  }) {
    return ReservationNotice(
      noticeId: noticeId ?? this.noticeId,
      targetDate: targetDate ?? this.targetDate,
      targetStartTime: targetStartTime ?? this.targetStartTime,
      targetEndTime: targetEndTime ?? this.targetEndTime,
      reservedForType: reservedForType ?? this.reservedForType,
      reservedForId: reservedForId ?? this.reservedForId,
      venueType: venueType ?? this.venueType,
      openAt: openAt ?? this.openAt,
      slots: slots ?? this.slots,
      fallback: fallback ?? this.fallback,
      status: status ?? this.status,
      createdBy: createdBy ?? this.createdBy,
      publishedAt: publishedAt ?? this.publishedAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ReservationNotice && other.noticeId == noticeId;
  }

  @override
  int get hashCode => noticeId.hashCode;
}

/// 예약 공지 구장별 슬롯 (tasks)
class ReservationNoticeSlot {
  const ReservationNoticeSlot({
    required this.groundId,
    required this.groundName,
    this.address,
    this.url,
    this.managers,
    this.result,
    this.successBy,
    this.successAt,
  });

  final String groundId;
  final String groundName;
  /// 주소 (예: 서울 금천구 가산동 562-3)
  final String? address;
  final String? url;
  final List<String>? managers;
  final SlotResult? result;
  final String? successBy;
  final DateTime? successAt;

  ReservationNoticeSlot copyWith({
    String? groundId,
    String? groundName,
    String? address,
    String? url,
    List<String>? managers,
    SlotResult? result,
    String? successBy,
    DateTime? successAt,
  }) {
    return ReservationNoticeSlot(
      groundId: groundId ?? this.groundId,
      groundName: groundName ?? this.groundName,
      address: address ?? this.address,
      url: url ?? this.url,
      managers: managers ?? this.managers,
      result: result ?? this.result,
      successBy: successBy ?? this.successBy,
      successAt: successAt ?? this.successAt,
    );
  }
}

/// 대안 예약 정보 (금천구 실패 시)
class ReservationNoticeFallback {
  const ReservationNoticeFallback({
    this.title,
    this.openAtText,
    this.targetDateText,
    this.targetTime,
    this.fee,
    this.url,
    this.memo,
  });

  final String? title;
  final String? openAtText;
  final String? targetDateText;
  final String? targetTime;
  final int? fee;
  final String? url;
  final String? memo;

  ReservationNoticeFallback copyWith({
    String? title,
    String? openAtText,
    String? targetDateText,
    String? targetTime,
    int? fee,
    String? url,
    String? memo,
  }) {
    return ReservationNoticeFallback(
      title: title ?? this.title,
      openAtText: openAtText ?? this.openAtText,
      targetDateText: targetDateText ?? this.targetDateText,
      targetTime: targetTime ?? this.targetTime,
      fee: fee ?? this.fee,
      url: url ?? this.url,
      memo: memo ?? this.memo,
    );
  }
}

enum ReservationNoticeForType {
  class_,
  match;

  String get value {
    switch (this) {
      case ReservationNoticeForType.class_:
        return 'class';
      case ReservationNoticeForType.match:
        return 'match';
    }
  }

  static ReservationNoticeForType? fromString(String? value) {
    if (value == null) return null;
    switch (value) {
      case 'class':
        return ReservationNoticeForType.class_;
      case 'match':
        return ReservationNoticeForType.match;
      default:
        return null;
    }
  }
}

enum VenueType {
  geumcheon,
  seoul;

  String get value {
    switch (this) {
      case VenueType.geumcheon:
        return 'geumcheon';
      case VenueType.seoul:
        return 'seoul';
    }
  }

  static VenueType? fromString(String? value) {
    if (value == null) return null;
    switch (value) {
      case 'geumcheon':
        return VenueType.geumcheon;
      case 'seoul':
        return VenueType.seoul;
      default:
        return null;
    }
  }
}

enum SlotResult {
  pending,
  success,
  failed;

  String get value {
    switch (this) {
      case SlotResult.pending:
        return 'pending';
      case SlotResult.success:
        return 'success';
      case SlotResult.failed:
        return 'failed';
    }
  }

  static SlotResult? fromString(String? value) {
    if (value == null) return null;
    switch (value) {
      case 'pending':
        return SlotResult.pending;
      case 'success':
        return SlotResult.success;
      case 'failed':
        return SlotResult.failed;
      default:
        return null;
    }
  }
}

enum ReservationNoticeStatus {
  pending,
  published,
  completed;

  String get value {
    switch (this) {
      case ReservationNoticeStatus.pending:
        return 'pending';
      case ReservationNoticeStatus.published:
        return 'published';
      case ReservationNoticeStatus.completed:
        return 'completed';
    }
  }

  static ReservationNoticeStatus? fromString(String? value) {
    if (value == null) return null;
    switch (value) {
      case 'pending':
        return ReservationNoticeStatus.pending;
      case 'published':
        return ReservationNoticeStatus.published;
      case 'completed':
        return ReservationNoticeStatus.completed;
      default:
        return null;
    }
  }
}
