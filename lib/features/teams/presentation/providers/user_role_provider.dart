import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_state_provider.dart';
import '../providers/current_team_provider.dart';

/// 현재 사용자의 현재 팀 내 역할 Provider
final currentUserRoleProvider = FutureProvider<MemberRole?>((ref) async {
  final user = ref.watch(currentUserProvider);
  final teamId = ref.watch(currentTeamIdProvider);
  
  if (user == null || teamId == null) return null;

  final firestore = FirebaseFirestore.instance;
  final memberDoc = await firestore
      .collection('teams')
      .doc(teamId)
      .collection('members')
      .doc(user.uid)
      .get();

  if (!memberDoc.exists) return null;

  final data = memberDoc.data()!;
  final roleString = data['role'] as String?;
  
  return MemberRole.fromString(roleString);
});

/// 역할별 권한 체크 Provider
final hasPermissionProvider = Provider.family<bool, Permission>((ref, permission) {
  final roleAsync = ref.watch(currentUserRoleProvider);
  
  return roleAsync.when(
    data: (role) => _checkPermission(role, permission),
    loading: () => false,
    error: (_, __) => false,
  );
});

bool _checkPermission(MemberRole? role, Permission permission) {
  if (role == null) return false;

  switch (permission) {
    case Permission.admin:
      return role == MemberRole.admin;
    case Permission.treasurer:
      return role == MemberRole.admin || role == MemberRole.treasurer;
    case Permission.coach:
      return role == MemberRole.admin || role == MemberRole.coach;
    case Permission.member:
      return true; // 모든 멤버는 기본 권한 있음
  }
}

enum Permission {
  admin,
  treasurer,
  coach,
  member,
}

/// 멤버 역할 Enum
enum MemberRole {
  admin,
  treasurer,
  coach,
  member;

  String get value {
    switch (this) {
      case MemberRole.admin:
        return 'admin';
      case MemberRole.treasurer:
        return 'treasurer';
      case MemberRole.coach:
        return 'coach';
      case MemberRole.member:
        return 'member';
    }
  }

  static MemberRole? fromString(String? value) {
    if (value == null) return null;
    switch (value) {
      case 'admin':
        return MemberRole.admin;
      case 'treasurer':
        return MemberRole.treasurer;
      case 'coach':
        return MemberRole.coach;
      case 'member':
        return MemberRole.member;
      default:
        return null;
    }
  }
}
