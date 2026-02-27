import 'package:cloud_firestore/cloud_firestore.dart' hide Transaction;

import '../../domain/entities/transaction.dart';

/// 거래 내역 모델 (Firestore 변환 포함)
class TransactionModel extends Transaction {
  const TransactionModel({
    required super.transactionId,
    required super.type,
    super.amount,
    super.userId,
    super.description,
    super.status,
    super.date,
    super.category,
    super.memo,
    super.createdBy,
    super.createdAt,
    super.completedAt,
  });

  factory TransactionModel.fromFirestore(
    String id,
    Map<String, dynamic> json,
  ) {
    return TransactionModel(
      transactionId: id,
      type: TransactionType.fromString(json['type'] as String?) ??
          TransactionType.payment,
      amount: json['amount'] as int?,
      userId: json['userId'] as String?,
      description: json['description'] as String?,
      status: TransactionStatus.fromString(json['status'] as String?),
      date: (json['date'] as Timestamp?)?.toDate(),
      category: json['category'] as String?,
      memo: json['memo'] as String?,
      createdBy: json['createdBy'] as String?,
      createdAt: (json['createdAt'] as Timestamp?)?.toDate(),
      completedAt: (json['completedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'type': type.value,
      if (amount != null) 'amount': amount,
      if (userId != null) 'userId': userId,
      if (description != null) 'description': description,
      if (status != null) 'status': status!.value,
      if (date != null) 'date': Timestamp.fromDate(date!),
      if (category != null) 'category': category,
      if (memo != null) 'memo': memo,
      if (createdBy != null) 'createdBy': createdBy,
      if (createdAt != null) 'createdAt': Timestamp.fromDate(createdAt!),
      if (completedAt != null)
        'completedAt': Timestamp.fromDate(completedAt!),
    };
  }
}
