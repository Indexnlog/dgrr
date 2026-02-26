/// 거래 내역 엔티티
class Transaction {
  const Transaction({
    required this.transactionId,
    required this.type,
    this.amount,
    this.userId,
    this.description,
    this.status,
    this.createdAt,
    this.completedAt,
  });

  final String transactionId;
  final TransactionType type;
  final int? amount;
  final String? userId;
  final String? description;
  final TransactionStatus? status;
  final DateTime? createdAt;
  final DateTime? completedAt;

  Transaction copyWith({
    String? transactionId,
    TransactionType? type,
    int? amount,
    String? userId,
    String? description,
    TransactionStatus? status,
    DateTime? createdAt,
    DateTime? completedAt,
  }) {
    return Transaction(
      transactionId: transactionId ?? this.transactionId,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      userId: userId ?? this.userId,
      description: description ?? this.description,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Transaction && other.transactionId == transactionId;
  }

  @override
  int get hashCode => transactionId.hashCode;
}

enum TransactionType {
  payment,
  refund,
  fee;

  String get value {
    switch (this) {
      case TransactionType.payment:
        return 'payment';
      case TransactionType.refund:
        return 'refund';
      case TransactionType.fee:
        return 'fee';
    }
  }

  static TransactionType? fromString(String? value) {
    if (value == null) return null;
    switch (value) {
      case 'payment':
        return TransactionType.payment;
      case 'refund':
        return TransactionType.refund;
      case 'fee':
        return TransactionType.fee;
      default:
        return null;
    }
  }
}

enum TransactionStatus {
  pending,
  completed,
  failed;

  String get value {
    switch (this) {
      case TransactionStatus.pending:
        return 'pending';
      case TransactionStatus.completed:
        return 'completed';
      case TransactionStatus.failed:
        return 'failed';
    }
  }

  static TransactionStatus? fromString(String? value) {
    if (value == null) return null;
    switch (value) {
      case 'pending':
        return TransactionStatus.pending;
      case 'completed':
        return TransactionStatus.completed;
      case 'failed':
        return TransactionStatus.failed;
      default:
        return null;
    }
  }
}
