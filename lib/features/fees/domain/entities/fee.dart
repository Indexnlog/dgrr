/// 회비/수업비 엔티티
class Fee {
  const Fee({
    required this.feeId,
    required this.feeType,
    this.name,
    this.amount,
    this.periodStart,
    this.periodEnd,
    this.memo,
    this.isActive,
    this.createdBy,
    this.createdAt,
  });

  final String feeId;
  final FeeType feeType;
  final String? name;
  final int? amount;
  final DateTime? periodStart;
  final DateTime? periodEnd;
  final String? memo;
  final bool? isActive;
  final String? createdBy;
  final DateTime? createdAt;

  Fee copyWith({
    String? feeId,
    FeeType? feeType,
    String? name,
    int? amount,
    DateTime? periodStart,
    DateTime? periodEnd,
    String? memo,
    bool? isActive,
    String? createdBy,
    DateTime? createdAt,
  }) {
    return Fee(
      feeId: feeId ?? this.feeId,
      feeType: feeType ?? this.feeType,
      name: name ?? this.name,
      amount: amount ?? this.amount,
      periodStart: periodStart ?? this.periodStart,
      periodEnd: periodEnd ?? this.periodEnd,
      memo: memo ?? this.memo,
      isActive: isActive ?? this.isActive,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Fee && other.feeId == feeId;
  }

  @override
  int get hashCode => feeId.hashCode;
}

enum FeeType {
  membership,
  lesson;

  String get value {
    switch (this) {
      case FeeType.membership:
        return 'membership';
      case FeeType.lesson:
        return 'lesson';
    }
  }

  static FeeType? fromString(String? value) {
    if (value == null) return null;
    switch (value) {
      case 'membership':
        return FeeType.membership;
      case 'lesson':
        return FeeType.lesson;
      default:
        return null;
    }
  }
}
