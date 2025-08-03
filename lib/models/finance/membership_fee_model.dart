import 'package:cloud_firestore/cloud_firestore.dart';

class MembershipFeeModel {
  final String id;
  final String teamId; // ✅ 공통 필드
  final int amount;
  final Timestamp periodStart;
  final Timestamp periodEnd;
  final String feeType;
  final String memo;
  final String createdBy;
  final Timestamp createdAt;
  final bool isActive;

  MembershipFeeModel({
    required this.id,
    required this.teamId,
    required this.amount,
    required this.periodStart,
    required this.periodEnd,
    required this.feeType,
    required this.memo,
    required this.createdBy,
    required this.createdAt,
    required this.isActive,
  });

  factory MembershipFeeModel.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return MembershipFeeModel(
      id: doc.id,
      teamId: data['teamId'] ?? '',
      amount: data['amount'] ?? 0,
      periodStart: data['periodStart'] ?? Timestamp.now(),
      periodEnd: data['periodEnd'] ?? Timestamp.now(),
      feeType: data['feeType'] ?? '',
      memo: data['memo'] ?? '',
      createdBy: data['createdBy'] ?? '',
      createdAt: data['createdAt'] ?? Timestamp.now(),
      isActive: data['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'teamId': teamId,
      'amount': amount,
      'periodStart': periodStart,
      'periodEnd': periodEnd,
      'feeType': feeType,
      'memo': memo,
      'createdBy': createdBy,
      'createdAt': createdAt,
      'isActive': isActive,
    };
  }
}
