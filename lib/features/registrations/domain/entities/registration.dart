/// 월별 회비제 등록 상태 (2026년 1월부터)
/// - 등록: 수업/경기 참가, 월 5만원
/// - 휴회: 개인 사유 불참, 회원 자격 유지, 월 2만원
/// - 미등록: 부상/출산 등 인정사유, 회비 없음
enum MembershipStatus {
  registered, // 등록 (5만원)
  paused,     // 휴회 (2만원)
  exempt;     // 미등록(인정사유) (0원)

  String get value {
    switch (this) {
      case MembershipStatus.registered:
        return 'registered';
      case MembershipStatus.paused:
        return 'paused';
      case MembershipStatus.exempt:
        return 'exempt';
    }
  }

  String get label {
    switch (this) {
      case MembershipStatus.registered:
        return '등록';
      case MembershipStatus.paused:
        return '휴회';
      case MembershipStatus.exempt:
        return '미등록(인정사유)';
    }
  }

  /// 해당 상태의 월 회비 (원)
  int get monthlyFee {
    switch (this) {
      case MembershipStatus.registered:
        return 50000;
      case MembershipStatus.paused:
        return 20000;
      case MembershipStatus.exempt:
        return 0;
    }
  }

  static MembershipStatus? fromString(String? value) {
    if (value == null) return null;
    switch (value) {
      case 'registered':
        return MembershipStatus.registered;
      case 'paused':
        return MembershipStatus.paused;
      case 'exempt':
        return MembershipStatus.exempt;
      default:
        return null;
    }
  }
}

/// 등록 정보 엔티티
class Registration {
  const Registration({
    required this.registrationId,
    required this.eventId,
    required this.userId,
    this.userName,
    this.uniformNo,
    this.photoUrl,
    this.type,
    this.status,
    this.membershipStatus,
    this.createdAt,
    this.updatedAt,
  });

  final String registrationId;
  final String eventId;
  final String userId;
  final String? userName;
  final int? uniformNo;
  final String? photoUrl;
  final RegistrationType? type;
  final RegistrationStatus? status;
  /// 월별 등록 여부 투표 결과 (등록/휴회/미등록)
  final MembershipStatus? membershipStatus;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Registration copyWith({
    String? registrationId,
    String? eventId,
    String? userId,
    String? userName,
    int? uniformNo,
    String? photoUrl,
    RegistrationType? type,
    RegistrationStatus? status,
    MembershipStatus? membershipStatus,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Registration(
      registrationId: registrationId ?? this.registrationId,
      eventId: eventId ?? this.eventId,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      uniformNo: uniformNo ?? this.uniformNo,
      photoUrl: photoUrl ?? this.photoUrl,
      type: type ?? this.type,
      status: status ?? this.status,
      membershipStatus: membershipStatus ?? this.membershipStatus,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Registration &&
        other.registrationId == registrationId;
  }

  @override
  int get hashCode => registrationId.hashCode;
}

enum RegistrationType {
  class_,
  match,
  event;

  String get value {
    switch (this) {
      case RegistrationType.class_:
        return 'class';
      case RegistrationType.match:
        return 'match';
      case RegistrationType.event:
        return 'event';
    }
  }

  static RegistrationType? fromString(String? value) {
    if (value == null) return null;
    switch (value) {
      case 'class':
        return RegistrationType.class_;
      case 'match':
        return RegistrationType.match;
      case 'event':
        return RegistrationType.event;
      default:
        return null;
    }
  }
}

enum RegistrationStatus {
  registered,
  cancelled,
  attended,
  absent,
  pending,
  paid;

  String get value {
    switch (this) {
      case RegistrationStatus.registered:
        return 'registered';
      case RegistrationStatus.cancelled:
        return 'cancelled';
      case RegistrationStatus.attended:
        return 'attended';
      case RegistrationStatus.absent:
        return 'absent';
      case RegistrationStatus.pending:
        return 'pending';
      case RegistrationStatus.paid:
        return 'paid';
    }
  }

  static RegistrationStatus? fromString(String? value) {
    if (value == null) return null;
    switch (value) {
      case 'registered':
        return RegistrationStatus.registered;
      case 'cancelled':
        return RegistrationStatus.cancelled;
      case 'attended':
        return RegistrationStatus.attended;
      case 'absent':
        return RegistrationStatus.absent;
      case 'pending':
        return RegistrationStatus.pending;
      case 'paid':
        return RegistrationStatus.paid;
      default:
        return null;
    }
  }
}
