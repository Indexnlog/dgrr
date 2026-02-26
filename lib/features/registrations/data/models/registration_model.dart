import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/registration.dart';

/// 등록 정보 모델 (Firestore 변환 포함)
class RegistrationModel extends Registration {
  const RegistrationModel({
    required super.registrationId,
    required super.eventId,
    required super.userId,
    super.userName,
    super.uniformNo,
    super.photoUrl,
    super.type,
    super.status,
    super.membershipStatus,
    super.createdAt,
    super.updatedAt,
  });

  factory RegistrationModel.fromFirestore(
    String id,
    Map<String, dynamic> json,
  ) {
    return RegistrationModel(
      registrationId: id,
      eventId: json['eventId'] as String? ?? '',
      userId: json['userId'] as String? ?? '',
      userName: json['userName'] as String?,
      uniformNo: json['uniformNo'] as int?,
      photoUrl: json['photoUrl'] as String?,
      type: RegistrationType.fromString(json['type'] as String?),
      status: RegistrationStatus.fromString(json['status'] as String?),
      membershipStatus:
          MembershipStatus.fromString(json['membershipStatus'] as String?),
      createdAt: (json['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (json['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'eventId': eventId,
      'userId': userId,
      if (userName != null) 'userName': userName,
      if (uniformNo != null) 'uniformNo': uniformNo,
      if (photoUrl != null) 'photoUrl': photoUrl,
      if (type != null) 'type': type!.value,
      if (status != null) 'status': status!.value,
      if (membershipStatus != null)
        'membershipStatus': membershipStatus!.value,
      if (createdAt != null) 'createdAt': Timestamp.fromDate(createdAt!),
      if (updatedAt != null) 'updatedAt': Timestamp.fromDate(updatedAt!),
    };
  }
}
