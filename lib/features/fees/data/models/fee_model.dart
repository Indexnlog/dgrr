import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/fee.dart';

/// 회비/수업비 모델 (Firestore 변환 포함)
class FeeModel extends Fee {
  const FeeModel({
    required super.feeId,
    required super.feeType,
    super.name,
    super.amount,
    super.periodStart,
    super.periodEnd,
    super.memo,
    super.isActive,
    super.createdBy,
    super.createdAt,
  });

  factory FeeModel.fromFirestore(String id, Map<String, dynamic> json) {
    return FeeModel(
      feeId: id,
      feeType: FeeType.fromString(json['feeType'] as String?) ?? FeeType.membership,
      name: json['name'] as String?,
      amount: json['amount'] as int?,
      periodStart: (json['periodStart'] as Timestamp?)?.toDate(),
      periodEnd: (json['periodEnd'] as Timestamp?)?.toDate(),
      memo: json['memo'] as String?,
      isActive: json['isActive'] as bool?,
      createdBy: json['createdBy'] as String?,
      createdAt: (json['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'feeType': feeType.value,
      if (name != null) 'name': name,
      if (amount != null) 'amount': amount,
      if (periodStart != null)
        'periodStart': Timestamp.fromDate(periodStart!),
      if (periodEnd != null) 'periodEnd': Timestamp.fromDate(periodEnd!),
      if (memo != null) 'memo': memo,
      if (isActive != null) 'isActive': isActive,
      if (createdBy != null) 'createdBy': createdBy,
      if (createdAt != null) 'createdAt': Timestamp.fromDate(createdAt!),
    };
  }
}
