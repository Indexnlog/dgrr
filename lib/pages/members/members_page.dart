import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'role_manage_page.dart';

class MembersPage extends StatelessWidget {
  final String teamId;
  const MembersPage({super.key, required this.teamId});

  bool get isAdmin {
    const adminUid = 'XpUVXbqUf5NbaQ355cXMaHYdhIq2';
    return FirebaseAuth.instance.currentUser?.uid == adminUid;
  }

  @override
  Widget build(BuildContext context) {
    final membersRef = FirebaseFirestore.instance
        .collection('teams')
        .doc(teamId)
        .collection('members');

    return Scaffold(
      appBar: AppBar(title: const Text('👥 멤버 목록')),
      body: StreamBuilder<QuerySnapshot>(
        stream: membersRef.orderBy('name').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData)
            return const Center(child: CircularProgressIndicator());

          final docs = snapshot.data!.docs;

          if (docs.isEmpty) {
            return const Center(child: Text('멤버가 없습니다.'));
          }

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final docId = docs[index].id;

              return ListTile(
                leading: const Icon(Icons.person),
                title: Text(data['name'] ?? '이름 없음'),
                subtitle: Text(data['role'] ?? '일반회원'),
                trailing: isAdmin
                    ? ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => RoleManagePage(
                                teamId: teamId,
                                memberUid: docId,
                              ),
                            ),
                          );
                        },
                        child: const Text('역할 변경'),
                      )
                    : null,
              );
            },
          );
        },
      ),
    );
  }
}
