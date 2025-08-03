// lib/providers/user_role_provider.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserRoleProvider extends ChangeNotifier {
  String? _role;
  String? _teamId;

  String? get role => _role;
  String? get teamId => _teamId;

  Future<void> loadUserRole() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final teamsSnapshot = await FirebaseFirestore.instance
        .collection('teams')
        .get();

    for (final teamDoc in teamsSnapshot.docs) {
      final memberDoc = await teamDoc.reference
          .collection('members')
          .doc(uid)
          .get();
      if (memberDoc.exists) {
        _role = memberDoc.data()?['role'] ?? '일반회원';
        _teamId = teamDoc.id;
        notifyListeners();
        return;
      }
    }
  }
}
