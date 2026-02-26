import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/ground_model.dart';

/// 구장 Firestore 데이터소스
class GroundRemoteDataSource {
  GroundRemoteDataSource({required this.firestore});

  final FirebaseFirestore firestore;

  CollectionReference<Map<String, dynamic>> _groundsRef(String teamId) =>
      firestore.collection('teams').doc(teamId).collection('grounds');

  /// 활성 구장 목록
  Stream<List<GroundModel>> watchActiveGrounds(String teamId) {
    return _groundsRef(teamId)
        .where('active', isEqualTo: true)
        .orderBy('priority')
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => GroundModel.fromFirestore(doc.id, doc.data()))
            .toList());
  }

  /// 전체 구장 목록 (관리용)
  Stream<List<GroundModel>> watchAllGrounds(String teamId) {
    return _groundsRef(teamId).snapshots().map((snap) {
      final list = snap.docs
          .map((doc) => GroundModel.fromFirestore(doc.id, doc.data()))
          .toList();
      list.sort((a, b) => (a.priority ?? 99).compareTo(b.priority ?? 99));
      return list;
    });
  }

  /// 구장 추가
  Future<String> createGround(String teamId, GroundModel ground) async {
    final doc = await _groundsRef(teamId).add(ground.toFirestore());
    return doc.id;
  }

  /// 구장 업데이트
  Future<void> updateGround(
    String teamId,
    String groundId,
    Map<String, dynamic> data,
  ) async {
    await _groundsRef(teamId).doc(groundId).update(data);
  }
}
