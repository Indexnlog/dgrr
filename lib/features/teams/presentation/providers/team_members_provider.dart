import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/member_model.dart';
import '../../domain/entities/member.dart';
import 'current_team_provider.dart';

/// 현재 팀의 활성 멤버 목록 (실시간 스트림)
final teamMembersProvider = StreamProvider<List<Member>>((ref) {
  final teamId = ref.watch(currentTeamIdProvider);
  if (teamId == null) return const Stream.empty();

  return FirebaseFirestore.instance
      .collection('teams')
      .doc(teamId)
      .collection('members')
      .where('status', isEqualTo: 'active')
      .snapshots()
      .map((snapshot) => snapshot.docs
          .map((doc) => MemberModel.fromFirestore(doc.id, doc.data()))
          .toList());
});

/// UID -> Member 매핑 (참석자 이름 조회용)
final memberMapProvider = Provider<Map<String, Member>>((ref) {
  final members = ref.watch(teamMembersProvider).value ?? [];
  return {for (final m in members) m.memberId: m};
});
