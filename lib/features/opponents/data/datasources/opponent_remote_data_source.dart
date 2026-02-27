import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/opponent.dart';
import '../models/opponent_model.dart';

/// 상대팀 Firestore 데이터소스
class OpponentRemoteDataSource {
  OpponentRemoteDataSource({required this.firestore});

  final FirebaseFirestore firestore;

  CollectionReference<Map<String, dynamic>> _opponentsRef(String teamId) =>
      firestore.collection('teams').doc(teamId).collection('opponents');

  /// 상대팀 목록 스트림
  Stream<List<OpponentModel>> watchOpponents(String teamId) {
    return _opponentsRef(teamId)
        .orderBy('name')
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => OpponentModel.fromFirestore(doc.id, doc.data()))
            .toList());
  }

  /// 상대팀 1건 조회
  Future<OpponentModel?> getOpponent(String teamId, String opponentId) async {
    final doc = await _opponentsRef(teamId).doc(opponentId).get();
    if (!doc.exists) return null;
    return OpponentModel.fromFirestore(doc.id, doc.data()!);
  }

  /// 상대팀 생성 또는 업데이트 (이름으로 검색)
  Future<String> upsertOpponent(
    String teamId, {
    required String name,
    String? contact,
    String status = 'seeking',
    String? opponentId,
  }) async {
    final ref = opponentId != null
        ? _opponentsRef(teamId).doc(opponentId)
        : _opponentsRef(teamId).doc();

    await ref.set({
      'name': name,
      if (contact != null) 'contact': contact,
      'status': status,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    return ref.id;
  }

  /// 상대팀 수정
  Future<void> updateOpponent(
    String teamId,
    String opponentId, {
    String? name,
    String? contact,
    String? status,
  }) async {
    final updates = <String, dynamic>{
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (name != null) updates['name'] = name;
    if (contact != null) updates['contact'] = contact;
    if (status != null) updates['status'] = status;
    await _opponentsRef(teamId).doc(opponentId).update(updates);
  }

  /// 상대팀 삭제
  Future<void> deleteOpponent(String teamId, String opponentId) async {
    await _opponentsRef(teamId).doc(opponentId).delete();
  }

  /// 전적 업데이트 (경기 종료 시 호출)
  Future<void> updateRecords(
    String teamId,
    String opponentId, {
    required List<String> recentResults,
    required OpponentRecords records,
  }) async {
    await _opponentsRef(teamId).doc(opponentId).update({
      'recentResults': recentResults,
      'records': {
        'wins': records.wins,
        'draws': records.draws,
        'losses': records.losses,
      },
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
