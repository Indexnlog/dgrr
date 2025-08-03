import 'package:cloud_firestore/cloud_firestore.dart';

class MemberModel {
  final String id; // memberId와 동일
  final String teamId;
  final String name;
  final String email;
  final String phone;
  final String photoUrl;
  final int number;
  final String uniformName;
  final String role; // 운영팀, 매치팀, 일반 등
  final bool isAdmin;
  final String status; // active, inactive, banned
  final Timestamp joinedAt;
  final Timestamp enrolledAt;
  final String homeAddress;
  final String workAddress;
  final String birthday; // yyyy-mm-dd 형식

  MemberModel({
    required this.id,
    required this.teamId,
    required this.name,
    required this.email,
    required this.phone,
    required this.photoUrl,
    required this.number,
    required this.uniformName,
    required this.role,
    required this.isAdmin,
    required this.status,
    required this.joinedAt,
    required this.enrolledAt,
    required this.homeAddress,
    required this.workAddress,
    required this.birthday,
  });

  factory MemberModel.fromDoc(dynamic doc) {
    final data = doc.data() as Map<String, dynamic>;
    return MemberModel(
      id: doc.id,
      teamId: data['teamId'] ?? '',
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      phone: data['phone'] ?? '',
      photoUrl: data['photoUrl'] ?? '',
      number: data['number'] ?? 0,
      uniformName: data['uniformName'] ?? '',
      role: data['role'] ?? '',
      isAdmin: data['isAdmin'] ?? false,
      status: data['status'] ?? 'active',
      joinedAt: data['joinedAt'] ?? Timestamp.now(),
      enrolledAt: data['enrolledAt'] ?? Timestamp.now(),
      homeAddress: data['homeAddress'] ?? '',
      workAddress: data['workAddress'] ?? '',
      birthday: data['birthday'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'teamId': teamId,
      'name': name,
      'email': email,
      'phone': phone,
      'photoUrl': photoUrl,
      'number': number,
      'uniformName': uniformName,
      'role': role,
      'isAdmin': isAdmin,
      'status': status,
      'joinedAt': joinedAt,
      'enrolledAt': enrolledAt,
      'homeAddress': homeAddress,
      'workAddress': workAddress,
      'birthday': birthday,
    };
  }
}
