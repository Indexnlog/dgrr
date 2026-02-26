import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/fee_model.dart';

/// 회비 Firestore 데이터소스
class FeeRemoteDataSource {
  FeeRemoteDataSource({required this.firestore});

  final FirebaseFirestore firestore;

  CollectionReference<Map<String, dynamic>> _feesRef(String teamId) =>
      firestore.collection('teams').doc(teamId).collection('fees');

  /// 활성 회비 목록 실시간 스트림
  Stream<List<FeeModel>> watchActiveFees(String teamId) {
    return _feesRef(teamId)
        .where('isActive', isEqualTo: true)
        .orderBy('periodStart', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => FeeModel.fromFirestore(doc.id, doc.data()))
            .toList());
  }

  /// 전체 회비 목록
  Stream<List<FeeModel>> watchAllFees(String teamId) {
    return _feesRef(teamId)
        .orderBy('createdAt', descending: true)
        .limit(12)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => FeeModel.fromFirestore(doc.id, doc.data()))
            .toList());
  }

  /// 회비 생성 (총무)
  Future<String> createFee(String teamId, FeeModel fee) async {
    final doc = await _feesRef(teamId).add(fee.toFirestore());
    return doc.id;
  }

  /// 회비 업데이트
  Future<void> updateFee(
      String teamId, String feeId, Map<String, dynamic> data) async {
    await _feesRef(teamId).doc(feeId).update(data);
  }
}
