import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // 👉 나중에 Firestore 연동 후 아래 데이터를 실제 값으로 교체하면 됨
    final String nickname = '홍길동';
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

    return Scaffold(
      appBar: AppBar(title: const Text('홈')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 👋 인사 영역
            Text(
              '안녕하세요, $nickname님 ⚽️',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 24),

            // 📌 등록 기간 배너
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
                    Expanded(
                      child: Text(
                        '다음 달 등록 기간입니다 (7/21~25)',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        // 👉 일정 탭으로 이동
                        // MainPage에서 BottomNavigation index를 바꾸는 로직 연결 필요
                      },
                      child: const Text('지금 등록하기'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],

            // ✅ 출석 현황
            Text('이번 달 출석 현황', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text('수업 ${classCount}회 / 매치 ${matchCount}회'),
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
                    // 👉 일정 탭 상세로 이동
                  },
                ),
              );
            }).toList(),
            const SizedBox(height: 24),

            // 📢 공지
            Text('최근 공지', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            ...notices.map((notice) {
              return ListTile(
                leading: const Icon(Icons.campaign, color: Colors.redAccent),
                title: Text(notice),
                onTap: () {
                  // 👉 공지 상세 보기 로직
                },
              );
            }).toList(),
            const SizedBox(height: 24),

            // 🔗 빠른 액션 버튼
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
              ],
            ),
          ],
        ),
      ),
    );
  }
}
