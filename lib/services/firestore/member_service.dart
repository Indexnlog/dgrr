import 'package:cloud_firestore/cloud_firestore.dart';

class MemberService {
  /// ✅ 멤버 추가 (실제 데이터 받기)
  static Future<void> addMember({
    required String memberId,
    required String name,
    required String uniformName,
    required int number,
    required String phone,
    required String role,
    required String createdByUid,
  }) async {
    await FirebaseFirestore.instance.collection('members').add({
      'memberId': memberId,
      'name': name,
      'uniformName': uniformName,
      'number': number,
      'phone': phone,
      'role': role,
      'createdAt': FieldValue.serverTimestamp(),
      'createdBy': createdByUid,
      'status': 'active',
    });
  }

  /// ✅ 멤버 실시간 구독
  static Stream<QuerySnapshot> getMembersStream() {
    return FirebaseFirestore.instance
        .collection('members')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }
}
