import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_state_provider.dart';

/// 사용자가 속한 팀 목록 Provider
final userTeamsProvider = FutureProvider<List<String>>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return [];

  final firestore = FirebaseFirestore.instance;
  
  // members 컬렉션에서 현재 사용자가 속한 팀들 조회
  final membersSnapshot = await firestore
      .collectionGroup('members')
      .where('memberId', isEqualTo: user.uid)
      .where('status', isEqualTo: 'active')
      .get();

  // teamId 추출 (경로에서)
  final teamIds = membersSnapshot.docs
      .map((doc) {
        // 경로: teams/{teamId}/members/{memberId}
        final pathParts = doc.reference.path.split('/');
        if (pathParts.length >= 2 && pathParts[0] == 'teams') {
          return pathParts[1];
        }
        return null;
      })
      .where((id) => id != null)
      .cast<String>()
      .toList();

  return teamIds;
});
