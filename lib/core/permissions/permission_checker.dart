import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/teams/presentation/providers/user_role_provider.dart'
    show Permission, hasPermissionProvider;

/// 권한 체크 헬퍼 클래스
class PermissionChecker {
  /// 특정 권한이 있는지 확인
  static bool hasPermission(WidgetRef ref, Permission permission) {
    return ref.read(hasPermissionProvider(permission));
  }

  /// 관리자 권한 확인
  static bool isAdmin(WidgetRef ref) {
    return hasPermission(ref, Permission.admin);
  }

  /// 회계 담당자 권한 확인
  static bool isTreasurer(WidgetRef ref) {
    return hasPermission(ref, Permission.treasurer);
  }

  /// 코치 권한 확인
  static bool isCoach(WidgetRef ref) {
    return hasPermission(ref, Permission.coach);
  }

  /// 멤버 권한 확인 (기본 권한)
  static bool isMember(WidgetRef ref) {
    return hasPermission(ref, Permission.member);
  }
}
