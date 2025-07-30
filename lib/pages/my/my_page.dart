import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// ✅ 프로필 수정 페이지
import '../profile/profile_edit_page.dart';

// ✅ 관리 페이지들
import '../finance/transaction_management_page.dart';
import '../reservations/reservation_management_page.dart';
import '../notices/notice_management_page.dart';
import '../votes/vote_management_page.dart';
import '../finance/fee_management_page.dart';

class MyPage extends StatelessWidget {
  const MyPage({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      return const Scaffold(body: Center(child: Text('로그인이 필요합니다.')));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('🙋 My')),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('members')
            .doc(currentUser.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('회원 정보가 없습니다.'));
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;
          final name = data['name'] ?? '이름 없음';
          final uniformNumber = data['number']?.toString() ?? '-';
          final joinDate = (data['joinDate'] as Timestamp?)?.toDate();
          final photoUrl = data['photoUrl'];

          // 입단일 경과일 계산
          int daysTogether = 0;
          String joinDateStr = '';
          if (joinDate != null) {
            final diff = DateTime.now().difference(joinDate);
            daysTogether = diff.inDays;
            joinDateStr =
                '${joinDate.year}.${joinDate.month.toString().padLeft(2, '0')}.${joinDate.day.toString().padLeft(2, '0')} (함께한 지 $daysTogether일)';
          }

          return SingleChildScrollView(
            child: Column(
              children: [
                // ✅ 프로필 카드
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 40,
                            backgroundImage:
                                (photoUrl != null && photoUrl != '')
                                ? NetworkImage(photoUrl)
                                : null,
                            child: (photoUrl == null || photoUrl == '')
                                ? const Icon(Icons.person, size: 40)
                                : null,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  name,
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text('유니폼: $uniformNumber번'),
                                const SizedBox(height: 4),
                                if (joinDateStr.isNotEmpty)
                                  Text('입단일: $joinDateStr'),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // ✅ 수정하기 / 로그아웃 버튼
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.edit),
                          label: const Text('수정하기'),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    ProfileEditPage(uid: currentUser.uid),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.logout),
                          label: const Text('로그아웃'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                          ),
                          onPressed: () async {
                            await FirebaseAuth.instance.signOut();
                          },
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),
                const Divider(),

                // ✅ 메뉴 리스트
                ListTile(
                  leading: const Icon(Icons.monetization_on),
                  title: const Text('💰 회비 관리'),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const FeeManagementPage(),
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.sports_soccer),
                  title: const Text('🏟 구장 예약 관리'),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ReservationManagementPage(),
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.campaign),
                  title: const Text('📋 공지 관리'),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const NoticeManagementPage(),
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.how_to_vote),
                  title: const Text('🗳 투표 관리'),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const VoteManagementPage(),
                      ),
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
