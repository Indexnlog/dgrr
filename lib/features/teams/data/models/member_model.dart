import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/member.dart';

/// 멤버 모델 (Firestore 변환 포함)
class MemberModel extends Member {
  const MemberModel({
    required super.memberId,
    required super.name,
    super.number,
    super.uniformName,
    super.phone,
    super.email,
    super.photoUrl,
    super.birthday,
    super.homeAddress,
    super.workAddress,
    super.department,
    super.role,
    super.status,
    super.isAdmin,
    super.joinedAt,
    super.enrolledAt,
    super.memo,
  });

  factory MemberModel.fromFirestore(String id, Map<String, dynamic> json) {
    return MemberModel(
      memberId: id,
      name: json['name'] as String? ?? '',
      number: json['number'] as int?,
      uniformName: json['uniformName'] as String?,
      phone: json['phone'] as String?,
      email: json['email'] as String?,
      photoUrl: json['photoUrl'] as String?,
      birthday: json['birthday'] as String?,
      homeAddress: json['homeAddress'] as String?,
      workAddress: json['workAddress'] as String?,
      department: json['department'] as String?,
      role: json['role'] as String?,
      status: MemberStatus.fromString(json['status'] as String?),
      isAdmin: json['isAdmin'] as bool?,
      joinedAt: (json['joinedAt'] as Timestamp?)?.toDate(),
      enrolledAt: (json['enrolledAt'] as Timestamp?)?.toDate(),
      memo: json['memo'] as String?,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'memberId': memberId,
      'name': name,
      if (number != null) 'number': number,
      if (uniformName != null) 'uniformName': uniformName,
      if (phone != null) 'phone': phone,
      if (email != null) 'email': email,
      if (photoUrl != null) 'photoUrl': photoUrl,
      if (birthday != null) 'birthday': birthday,
      if (homeAddress != null) 'homeAddress': homeAddress,
      if (workAddress != null) 'workAddress': workAddress,
      if (department != null) 'department': department,
      if (role != null) 'role': role,
      if (status != null) 'status': status!.value,
      if (isAdmin != null) 'isAdmin': isAdmin,
      if (joinedAt != null) 'joinedAt': Timestamp.fromDate(joinedAt!),
      if (enrolledAt != null) 'enrolledAt': Timestamp.fromDate(enrolledAt!),
      if (memo != null) 'memo': memo,
    };
  }

  @override
  MemberModel copyWith({
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
    return MemberModel(
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
}
