import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    // 로그인 안 된 경우
    if (currentUser == null) {
      return const Scaffold(body: Center(child: Text('로그인이 필요합니다.')));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('홈')),
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

          // 🔹 Firestore 데이터 읽기
          final data = snapshot.data!.data() as Map<String, dynamic>;
          final nickname = data['name'] ?? '회원';
          final role = data['role'] ?? '일반회원';
          final department = data['department'] ?? '';

          // 👉 퀵메뉴 노출 여부
          final bool canAddClass = (role == '운영팀' || department == '수업관리팀');
          final bool canAddMatch = (role == '운영팀' || department == '경기관리팀');

          // 👉 예시용 데이터 (추후 Firestore 연동)
          final bool isRegisterPeriod = true;
          final int classCount = 3;
          final int matchCount = 1;

          final upcomingSchedules = [
            {
              'type': '수업',
              'date': '목 7/25',
              'place': '구로풋살장',
              'time': '20:00',
              'attend': 12,
            },
            {
              'type': '매치',
              'date': '일 7/28',
              'place': '블루스타즈구장',
              'time': '18:00',
              'attend': 9,
            },
            {
              'type': '수업',
              'date': '화 7/30',
              'place': '신림풋살장',
              'time': '19:00',
              'attend': 8,
            },
          ];

          final notices = ['7월 24일 구장 변경 안내', 'MVP 투표 시작!'];

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 👋 인사
                Text(
                  '안녕하세요, $nickname님 ⚽️',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 24),

                // 📌 등록기간 배너
                if (isRegisterPeriod) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.event_available, color: Colors.orange),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            '다음 달 등록 기간입니다 (7/21~25)',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            // 👉 일정 탭으로 이동
                          },
                          child: const Text('지금 등록하기'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // ✅ 출석 현황
                Text(
                  '이번 달 출석 현황',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text('수업 $classCount회 / 매치 $matchCount회'),
                const SizedBox(height: 24),

                // 📅 다가오는 일정
                Text('다가오는 일정', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                ...upcomingSchedules.map((schedule) {
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: Icon(
                        schedule['type'] == '수업'
                            ? Icons.school
                            : Icons.sports_soccer,
                        color: schedule['type'] == '수업'
                            ? Colors.blue
                            : Colors.green,
                      ),
                      title: Text(
                        '[${schedule['type']}] ${schedule['date']} ${schedule['time']}',
                      ),
                      subtitle: Text(
                        '@${schedule['place']} (${schedule['attend']}명 참석)',
                      ),
                      onTap: () {
                        // 👉 상세 이동
                      },
                    ),
                  );
                }),
                const SizedBox(height: 24),

                // 📢 공지
                Text('최근 공지', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                ...notices.map((notice) {
                  return ListTile(
                    leading: const Icon(
                      Icons.campaign,
                      color: Colors.redAccent,
                    ),
                    title: Text(notice),
                    onTap: () {
                      // 👉 공지 상세
                    },
                  );
                }),
                const SizedBox(height: 24),

                // 🔗 빠른 액션
                Text('빠른 액션', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ElevatedButton.icon(
                      icon: const Icon(Icons.event_note),
                      label: const Text('다음달 등록하기'),
                      onPressed: () {
                        // 👉 일정 탭 이동
                      },
                    ),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.assignment),
                      label: const Text('내 출석 보기'),
                      onPressed: () {
                        // 👉 개인 탭 이동
                      },
                    ),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.sports),
                      label: const Text('매치 전적 보기'),
                      onPressed: () {
                        // 👉 매치 탭 이동
                      },
                    ),

                    // ✅ 수업 등록 버튼 (조건부)
                    if (canAddClass)
                      ElevatedButton.icon(
                        icon: const Icon(Icons.add_box),
                        label: const Text('수업 등록'),
                        onPressed: () {
                          Navigator.pushNamed(context, '/classAdd');
                        },
                      ),

                    // ✅ 매치 등록 버튼 (조건부)
                    if (canAddMatch)
                      ElevatedButton.icon(
                        icon: const Icon(Icons.add_task),
                        label: const Text('매치 등록'),
                        onPressed: () {
                          Navigator.pushNamed(context, '/matchAdd');
                        },
                      ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
