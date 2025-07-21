import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../services/firestore_service.dart';
import 'profile_setup_page.dart';
import 'profile_edit_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _counter = 0;

  // 🔧 상태변수들
  String _searchKeyword = '';
  String _selectedDepartment = '전체';
  String _selectedRole = '전체';
  String _selectedStatus = '전체';

  // 🔑 Google 로그인 후 Firestore 조회
  Future<void> _signInWithGoogle() async {
    try {
      final googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) return;

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await FirebaseAuth.instance.signInWithCredential(
        credential,
      );
      final user = userCredential.user;

      if (user != null) {
        final memberDoc = await FirebaseFirestore.instance
            .collection('members')
            .doc(user.uid)
            .get();

        if (memberDoc.exists) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('기존 회원입니다. ${user.displayName}님 환영합니다!')),
          );
        } else {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ProfileSetupPage()),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('구글 로그인 실패: $e')));
    }
  }

  Future<void> _addTestMember() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      await FirestoreService.addTestMember(uid);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('✅ Firestore에 멤버 추가 완료!')));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('❌ Firestore 오류: $e')));
    }
  }

  void _incrementCounter() {
    setState(() {
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('홈 화면')),
      body: Column(
        children: [
          // 🔎 검색창
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: const InputDecoration(
                labelText: '이름 검색',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (value) {
                setState(() {
                  _searchKeyword = value.trim();
                });
              },
            ),
          ),

          // 📌 필터 영역
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Row(
              children: [
                // 부서 필터
                Expanded(
                  child: DropdownButton<String>(
                    value: _selectedDepartment,
                    isExpanded: true,
                    items: const [
                      DropdownMenuItem(value: '전체', child: Text('전체 부서')),
                      DropdownMenuItem(value: '운영팀', child: Text('운영팀')),
                      DropdownMenuItem(value: '수업관리팀', child: Text('수업관리팀')),
                      DropdownMenuItem(
                        value: '경기관리/대외협력팀',
                        child: Text('경기관리/대외협력팀'),
                      ),
                      DropdownMenuItem(value: '미정', child: Text('미정')),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedDepartment = value!;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 8),

                // 역할 필터
                Expanded(
                  child: DropdownButton<String>(
                    value: _selectedRole,
                    isExpanded: true,
                    items: const [
                      DropdownMenuItem(value: '전체', child: Text('전체 역할')),
                      DropdownMenuItem(value: '일반회원', child: Text('일반회원')),
                      DropdownMenuItem(value: '운영진', child: Text('운영진')),
                      DropdownMenuItem(value: '총무', child: Text('총무')),
                      DropdownMenuItem(value: '팀장', child: Text('팀장')),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedRole = value!;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 8),

                // 상태 필터
                Expanded(
                  child: DropdownButton<String>(
                    value: _selectedStatus,
                    isExpanded: true,
                    items: const [
                      DropdownMenuItem(value: '전체', child: Text('전체 상태')),
                      DropdownMenuItem(value: 'active', child: Text('active')),
                      DropdownMenuItem(value: '탈퇴', child: Text('탈퇴')),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedStatus = value!;
                      });
                    },
                  ),
                ),
              ],
            ),
          ),

          // 🔥 Firestore 실시간 데이터
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

                final docs = snapshot.data!.docs;

                // 🔧 검색 + 필터 적용
                final filtered = docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final name = (data['name'] ?? '') as String;
                  final department = (data['department'] ?? '') as String;
                  final role = (data['role'] ?? '') as String;
                  final status = (data['status'] ?? '') as String;

                  final matchesSearch =
                      _searchKeyword.isEmpty || name.toLowerCase().contains(_searchKeyword.toLowerCase());
                  final matchesDept =
                      _selectedDepartment == '전체' ||
                      department == _selectedDepartment;
                  final matchesRole =
                      _selectedRole == '전체' || role == _selectedRole;
                  final matchesStatus =
                      _selectedStatus == '전체' || status == _selectedStatus;

                  return matchesSearch &&
                      matchesDept &&
                      matchesRole &&
                      matchesStatus;
                }).toList();

                if (filtered.isEmpty) {
                  return const Center(child: Text('조건에 맞는 멤버가 없습니다.'));
                }

                return ListView.builder(
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final data = filtered[index].data() as Map<String, dynamic>;
                    inal name = (data['name'] ?? '') as String;
                    final number = data['number'] ?? '';
                    final createdBy = data['createdBy'] ?? 'unknown';

                    return ListTile(
                      leading: const Icon(Icons.person),
                      title: Text('$name (#$number)'),
                      subtitle: Text('작성자 UID: $createdBy'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.blue),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ProfileEditPage(
                                    docId: filtered[index].id,
                                  ),
                                ),
                              );
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: const Text('정말 삭제하시겠어요?'),
                                  content: const Text('탈퇴 처리됩니다.'),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(ctx),
                                      child: const Text('취소'),
                                    ),
                                    TextButton(
                                      onPressed: () async {
                                        await FirebaseFirestore.instance
                                            .collection('members')
                                            .doc(filtered[index].id)
                                            .update({'status': '탈퇴'});
                                        Navigator.pop(ctx);
                                      },
                                      child: const Text('확인'),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),

          const SizedBox(height: 20),

          ElevatedButton(
            onPressed: _signInWithGoogle,
            child: const Text('🔑 Google 로그인'),
          ),
          const SizedBox(height: 20),

          ElevatedButton(
            onPressed: _addTestMember,
            child: const Text('➕ Firestore에 멤버 추가'),
          ),
          const SizedBox(height: 20),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        child: const Icon(Icons.add),
      ),
    );
  }
}
