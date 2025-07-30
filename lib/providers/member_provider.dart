import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MemberProvider extends ChangeNotifier {
  Map<String, dynamic>? _memberData;
  bool _isLoading = false;

  Map<String, dynamic>? get memberData => _memberData;
  bool get isLoading => _isLoading;

  /// uid와 teamId를 받아 Firestore에서 멤버 데이터 로드
  Future<void> loadMemberData(String uid, String teamId) async {
    _isLoading = true;
    notifyListeners();

    try {
      final doc = await FirebaseFirestore.instance
          .collection('teams')
          .doc(teamId)
          .collection('members')
          .doc(uid)
          .get();

      if (doc.exists) {
        _memberData = doc.data();
      } else {
        _memberData = null;
      }
    } catch (e) {
      _memberData = null;
    }

    _isLoading = false;
    notifyListeners();
  }

  /// 필요 시 멤버 데이터 초기화
  void clear() {
    _memberData = null;
    notifyListeners();
  }
}
