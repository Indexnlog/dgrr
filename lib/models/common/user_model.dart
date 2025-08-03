import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String teamId;
  final String fcmToken;
  final String? deviceType;
  final String? appVersion;
  final Timestamp? lastLogin;

  UserModel({
    required this.uid,
    required this.teamId,
    required this.fcmToken,
    this.deviceType,
    this.appVersion,
    this.lastLogin,
  });

  factory UserModel.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      uid: doc.id,
      teamId: data['teamId'] ?? '',
      fcmToken: data['fcmToken'] ?? '',
      deviceType: data['deviceType'],
      appVersion: data['appVersion'],
      lastLogin: data['lastLogin'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'teamId': teamId,
      'fcmToken': fcmToken,
      'deviceType': deviceType,
      'appVersion': appVersion,
      'lastLogin': lastLogin,
    };
  }
}
