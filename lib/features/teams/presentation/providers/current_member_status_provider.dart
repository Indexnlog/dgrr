import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_state_provider.dart';
import '../../../domain/entities/member.dart';
import 'current_team_provider.dart';

/// 현재 사용자의 현재 팀 내 멤버 상태 (pending/active/rejected 등)
/// 팀 선택 후 승인 여부 판단용
final currentMemberStatusInTeamProvider =
    FutureProvider<MemberStatus?>((ref) async {
  final user = ref.watch(currentUserProvider);
  final teamId = ref.watch(currentTeamIdProvider);

  if (user == null || teamId == null) return null;

  final doc = await FirebaseFirestore.instance
      .collection('teams')
      .doc(teamId)
      .collection('members')
      .doc(user.uid)
      .get();

  if (!doc.exists) return null;
  final status = doc.data()?['status'] as String?;
  return MemberStatus.fromString(status);
});
