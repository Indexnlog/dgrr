/// 경기장 예약 엔티티
class Reservation {
  const Reservation({
    required this.reservationId,
    required this.groundId,
    this.reservedForType,
    this.reservedForId,
    this.date,
    this.startTime,
    this.endTime,
    this.status,
    this.paymentStatus,
    this.reservedBy,
    this.memo,
    this.createdAt,
  });

  final String reservationId;
  final String groundId;
  final ReservationForType? reservedForType;
  final String? reservedForId;
  final DateTime? date;
  final String? startTime;
  final String? endTime;
  final ReservationStatus? status;
  final PaymentStatus? paymentStatus;
  final String? reservedBy;
  final String? memo;
  final DateTime? createdAt;

  Reservation copyWith({
    String? reservationId,
    String? groundId,
    ReservationForType? reservedForType,
    String? reservedForId,
    DateTime? date,
    String? startTime,
    String? endTime,
    ReservationStatus? status,
    PaymentStatus? paymentStatus,
    String? reservedBy,
    String? memo,
    DateTime? createdAt,
  }) {
    return Reservation(
      reservationId: reservationId ?? this.reservationId,
      groundId: groundId ?? this.groundId,
      reservedForType: reservedForType ?? this.reservedForType,
      reservedForId: reservedForId ?? this.reservedForId,
      date: date ?? this.date,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      status: status ?? this.status,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      reservedBy: reservedBy ?? this.reservedBy,
      memo: memo ?? this.memo,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Reservation && other.reservationId == reservationId;
  }

  @override
  int get hashCode => reservationId.hashCode;
}

enum ReservationForType {
  class_,
  match,
  event;

  String get value {
    switch (this) {
      case ReservationForType.class_:
        return 'class';
      case ReservationForType.match:
        return 'match';
      case ReservationForType.event:
        return 'event';
    }
  }

  static ReservationForType? fromString(String? value) {
    if (value == null) return null;
    switch (value) {
      case 'class':
        return ReservationForType.class_;
      case 'match':
        return ReservationForType.match;
      case 'event':
        return ReservationForType.event;
      default:
        return null;
    }
  }
}

enum ReservationStatus {
  reserved,
  cancelled,
  completed;

  String get value {
    switch (this) {
      case ReservationStatus.reserved:
        return 'reserved';
      case ReservationStatus.cancelled:
        return 'cancelled';
      case ReservationStatus.completed:
        return 'completed';
    }
  }

  static ReservationStatus? fromString(String? value) {
    if (value == null) return null;
    switch (value) {
      case 'reserved':
        return ReservationStatus.reserved;
      case 'cancelled':
        return ReservationStatus.cancelled;
      case 'completed':
        return ReservationStatus.completed;
      default:
        return null;
    }
  }
}

enum PaymentStatus {
  paid,
  unpaid,
  refunded;

  String get value {
    switch (this) {
      case PaymentStatus.paid:
        return 'paid';
      case PaymentStatus.unpaid:
        return 'unpaid';
      case PaymentStatus.refunded:
        return 'refunded';
    }
  }

  static PaymentStatus? fromString(String? value) {
    if (value == null) return null;
    switch (value) {
      case 'paid':
        return PaymentStatus.paid;
      case 'unpaid':
        return PaymentStatus.unpaid;
      case 'refunded':
        return PaymentStatus.refunded;
      default:
        return null;
    }
  }
}
