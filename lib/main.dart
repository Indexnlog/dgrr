import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // ✅ Firestore

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Google Login Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const MyHomePage(title: 'Google Login & Firestore Test'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;

  // ✅ 카운터 증가
  void _incrementCounter() {
    setState(() {
      _counter++;
    });
  }

  // ✅ Google 로그인
  Future<void> _signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) return; // 로그인 취소

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await FirebaseAuth.instance.signInWithCredential(
        credential,
      );
      final user = userCredential.user;

      if (user != null) {
        print('✅ 구글 로그인 성공: ${user.displayName}, ${user.email}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('구글 로그인 성공! ${user.displayName}')),
        );
      }
    } catch (e) {
      print('❌ 구글 로그인 오류: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('구글 로그인 실패: $e')));
    }
  }

  // ✅ Firestore에 테스트 멤버 추가 (uid 포함)
  Future<void> _addTestMember() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      await FirebaseFirestore.instance.collection('members').add({
        'memberId': 'm001',
        'name': '홍길동',
        'uniformName': '길동',
        'number': 7,
        'phone': '010-1234-5678',
        'role': 'player',
        'createdAt': FieldValue.serverTimestamp(),
        'createdBy': uid, // 로그인한 사용자 UID
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('✅ Firestore에 멤버 추가 완료!')));
    } catch (e) {
      print('❌ Firestore 오류: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('❌ Firestore 오류: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Column(
        children: [
          // 🔥 Firestore members 컬렉션 실시간 출력
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('members')
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('아직 등록된 멤버가 없습니다.'));
                }

                final members = snapshot.data!.docs;

                return ListView.builder(
                  itemCount: members.length,
                  itemBuilder: (context, index) {
                    final data = members[index].data() as Map<String, dynamic>;
                    final name = data['name'] ?? '이름없음';
                    final number = data['number'] ?? '';
                    final createdBy = data['createdBy'] ?? 'unknown';
                    return ListTile(
                      leading: const Icon(Icons.person),
                      title: Text('$name (#$number)'),
                      subtitle: Text('작성자 UID: $createdBy'),
                    );
                  },
                );
              },
            ),
          ),

          // 아래는 기존 버튼들
          const SizedBox(height: 20),

          ElevatedButton(
            onPressed: _signInWithGoogle,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            child: const Text('🔑 Google 로그인'),
          ),

          const SizedBox(height: 20),

          ElevatedButton(
            onPressed: _addTestMember,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            child: const Text('➕ Firestore에 멤버 추가'),
          ),

          const SizedBox(height: 20),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ),
    );
  }
}
