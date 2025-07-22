import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  static Future<void> addTestMember(String? uid) async {
    await FirebaseFirestore.instance.collection('members').add({
      'memberId': 'm001',
      'name': '홍길동',
      'uniformName': '길동',
      'number': 7,
      'phone': '010-1234-5678',
      'role': 'player',
      'createdAt': FieldValue.serverTimestamp(),
      'createdBy': uid,
      'status': 'active',
    });
  }

  static Stream<QuerySnapshot> getMembersStream() {
    return FirebaseFirestore.instance
        .collection('members')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }
}
