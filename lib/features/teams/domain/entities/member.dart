/// 멤버 역할 상수 (일반 / 운영진 / 총무)
abstract class MemberRole {
  static const member = '일반';
  static const admin = '운영진';
  static const treasurer = '총무';

  static const all = [member, admin, treasurer];
}

/// 역할 기반 권한 체크 유틸리티
extension MemberPermissions on Member {
  /// 운영진 이상 (경기 관리, 공지 등록 등)
  bool get canManage =>
      role == MemberRole.admin ||
      role == MemberRole.treasurer ||
      isAdmin == true;

  /// 총무 전용 (회비 관리)
  bool get canManageFees =>
      role == MemberRole.treasurer || isAdmin == true;

  /// 운영진 전용 (매치 등록, 상대팀 관리 등)
  bool get canManageMatches =>
      role == MemberRole.admin || isAdmin == true;
}

/// 멤버 엔티티
class Member {
  const Member({
    required this.memberId,
    required this.name,
    this.number,
    this.uniformName,
    this.phone,
    this.email,
    this.photoUrl,
    this.birthday,
    this.homeAddress,
    this.workAddress,
    this.department,
    this.role,
    this.status,
    this.isAdmin,
    this.joinedAt,
    this.enrolledAt,
    this.memo,
  });

  final String memberId;
  final String name;
  final int? number;
  final String? uniformName;
  final String? phone;
  final String? email;
  final String? photoUrl;
  final String? birthday;
  final String? homeAddress;
  final String? workAddress;
  final String? department;
  final String? role;
  final MemberStatus? status;
  final bool? isAdmin;
  final DateTime? joinedAt;
  final DateTime? enrolledAt;
  /// 관리자 메모
  final String? memo;

  Member copyWith({
    String? memberId,
    String? name,
    int? number,
    String? uniformName,
    String? phone,
    String? email,
    String? photoUrl,
    String? birthday,
    String? homeAddress,
    String? workAddress,
    String? department,
    String? role,
    MemberStatus? status,
    bool? isAdmin,
    DateTime? joinedAt,
    DateTime? enrolledAt,
    String? memo,
  }) {
    return Member(
      memberId: memberId ?? this.memberId,
      name: name ?? this.name,
      number: number ?? this.number,
      uniformName: uniformName ?? this.uniformName,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      photoUrl: photoUrl ?? this.photoUrl,
      birthday: birthday ?? this.birthday,
      homeAddress: homeAddress ?? this.homeAddress,
      workAddress: workAddress ?? this.workAddress,
      department: department ?? this.department,
      role: role ?? this.role,
      status: status ?? this.status,
      isAdmin: isAdmin ?? this.isAdmin,
      joinedAt: joinedAt ?? this.joinedAt,
      enrolledAt: enrolledAt ?? this.enrolledAt,
      memo: memo ?? this.memo,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Member && other.memberId == memberId;
  }

  @override
  int get hashCode => memberId.hashCode;
}

enum MemberStatus {
  active,
  pending,
  rejected,
  left;

  String get value {
    switch (this) {
      case MemberStatus.active:
        return 'active';
      case MemberStatus.pending:
        return 'pending';
      case MemberStatus.rejected:
        return 'rejected';
      case MemberStatus.left:
        return 'left';
    }
  }

  static MemberStatus? fromString(String? value) {
    if (value == null) return null;
    switch (value) {
      case 'active':
        return MemberStatus.active;
      case 'pending':
        return MemberStatus.pending;
      case 'rejected':
        return MemberStatus.rejected;
      case 'left':
        return MemberStatus.left;
      default:
        return null;
    }
  }
}
