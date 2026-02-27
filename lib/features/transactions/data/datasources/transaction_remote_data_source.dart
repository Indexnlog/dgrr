import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/transaction.dart';
import '../models/transaction_model.dart';

/// 거래 Firestore 데이터소스
class TransactionRemoteDataSource {
  TransactionRemoteDataSource({required this.firestore});

  final FirebaseFirestore firestore;

  CollectionReference<Map<String, dynamic>> _txRef(String teamId) =>
      firestore.collection('teams').doc(teamId).collection('transactions');

  /// 경기 경비 정산: 참석자별로 1/N 금액 거래 생성
  Future<void> createMatchExpenseSettlement({
    required String teamId,
    required String matchId,
    required int totalAmount,
    required List<String> attendeeUids,
    required String createdBy,
  }) async {
    if (attendeeUids.isEmpty) return;
    final perPerson = totalAmount ~/ attendeeUids.length;

    final batch = firestore.batch();
    final now = DateTime.now();

    for (final uid in attendeeUids) {
      final ref = _txRef(teamId).doc();
      final tx = TransactionModel(
        transactionId: ref.id,
        type: TransactionType.expense,
        amount: perPerson,
        userId: uid,
        description: '경기 경비 ($matchId)',
        status: TransactionStatus.pending,
        date: now,
        category: '구장비',
        memo: '참석자 ${attendeeUids.length}명 분할',
        createdBy: createdBy,
        createdAt: now,
      );
      batch.set(ref, tx.toFirestore());
    }

    await batch.commit();
  }
}
