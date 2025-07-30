import 'package:cloud_firestore/cloud_firestore.dart';

class RegistrationModel {
  final String id;
  final String teamId;
  final String eventId;
  final String type; // class, match, event
  final String userId;
  final String userName;
  final String photoUrl;
  final int uniformNo;
  final String status; // registered, cancelled
  final Timestamp createdAt;
  final Timestamp updatedAt;

  RegistrationModel({
    required this.id,
    required this.teamId,
    required this.eventId,
    required this.type,
    required this.userId,
    required this.userName,
    required this.photoUrl,
    required this.uniformNo,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  factory RegistrationModel.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return RegistrationModel(
      id: doc.id,
      teamId: data['teamId'] ?? '',
      eventId: data['eventId'] ?? '',
      type: data['type'] ?? '',
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? '',
      photoUrl: data['photoUrl'] ?? '',
      uniformNo: data['uniformNo'] ?? 0,
      status: data['status'] ?? 'registered',
      createdAt: data['createdAt'] ?? Timestamp.now(),
      updatedAt: data['updatedAt'] ?? Timestamp.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'teamId': teamId,
      'eventId': eventId,
      'type': type,
      'userId': userId,
      'userName': userName,
      'photoUrl': photoUrl,
      'uniformNo': uniformNo,
      'status': status,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }
}
