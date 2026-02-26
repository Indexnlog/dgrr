import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../domain/repositories/team_repository.dart';

/// 팀 Repository 구현
class TeamRepositoryImpl implements TeamRepository {
  TeamRepositoryImpl(this.firestore, this.auth);

  final FirebaseFirestore firestore;
  final FirebaseAuth auth;

  @override
  Future<void> requestJoinTeam({
    required String teamId,
    required String userId,
  }) async {
    final currentUser = auth.currentUser;
    if (currentUser == null) {
      throw Exception('로그인이 필요합니다.');
    }

    // teams/{teamId}/members/{userId}에 멤버 신청 생성
    await firestore
        .collection('teams')
        .doc(teamId)
        .collection('members')
        .doc(userId)
        .set({
      'memberId': userId,
      'status': 'pending',
      'joinedAt': FieldValue.serverTimestamp(),
      // 나머지 필드는 관리자가 승인 후 업데이트
    }, SetOptions(merge: true));
  }

  @override
  Future<void> updateMemberPhotoUrl({
    required String teamId,
    required String memberId,
    required String photoUrl,
  }) async {
    await firestore
        .collection('teams')
        .doc(teamId)
        .collection('members')
        .doc(memberId)
        .update({'photoUrl': photoUrl});
  }
}
