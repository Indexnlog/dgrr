import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:provider/provider.dart';

import '../../providers/team_provider.dart';
import '../main_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool _isLoading = false;

  Future<void> _signInWithGoogle() async {
    setState(() => _isLoading = true);

    try {
      final googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        setState(() => _isLoading = false);
        return;
      }

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await FirebaseAuth.instance.signInWithCredential(
        credential,
      );
      final user = userCredential.user;

      if (user == null) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('로그인 실패')));
        return;
      }

      final teamId = context.read<TeamProvider>().teamId;
      if (teamId == null || teamId.isEmpty) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('팀이 선택되지 않았습니다.')));
        return;
      }

      final memberDocRef = FirebaseFirestore.instance
          .collection('teams')
          .doc(teamId)
          .collection('members')
          .doc(user.uid);

      final memberDoc = await memberDocRef.get();

      if (!memberDoc.exists) {
        // 신규 멤버 문서 생성 → 승인 대기 상태
        await memberDocRef.set({
          'uid': user.uid,
          'name': user.displayName,
          'email': user.email,
          'photoUrl': user.photoURL,
          'teamId': teamId,
          'status': 'pending', // 🔸 승인 대기
          'role': 'member',
          'joinedAt': FieldValue.serverTimestamp(),
        });

        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('가입 신청 완료! 승인을 기다려주세요.')));
        setState(() => _isLoading = false);
        return;
      }

      final data = memberDoc.data();
      final status = data?['status'];

      if (status != 'active') {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('현재 상태: $status. 승인 후 이용 가능합니다.')),
        );
        setState(() => _isLoading = false);
        return;
      }

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MainPage()),
      );
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('구글 로그인 오류: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('로그인')),
      body: Center(
        child: _isLoading
            ? const CircularProgressIndicator()
            : ElevatedButton.icon(
                icon: const Icon(Icons.login),
                label: const Text('구글로 로그인하기'),
                onPressed: _signInWithGoogle,
              ),
      ),
    );
  }
}
