import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final formattedDate = DateFormat('M월 d일 (E)', 'ko_KR').format(now);

    return Scaffold(
      appBar: AppBar(title: const Text('지구공 홈')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 👋 인사말
            Text(
              '안녕하세요, 홍길동님! ⚽️',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text('오늘은 $formattedDate입니다.'),
            const SizedBox(height: 24),

            // 📌 알림 배너
            Card(
              color: Colors.orange[50],
              child: ListTile(
                leading: const Icon(Icons.campaign, color: Colors.orange),
                title: const Text('다음 달 등록 기간입니다 (7/21~25)'),
                trailing: TextButton(
                  child: const Text('지금 등록하기'),
                  onPressed: () {
                    Navigator.pushNamed(context, '/classAdd');
                  },
                ),
              ),
            ),
            const SizedBox(height: 24),

            // ✅ 출석 현황
            Text('이번 달 출석 현황', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: 0.6, // TODO: Firestore에서 계산한 출석률로 대체
              backgroundColor: Colors.grey[300],
              color: Colors.green,
            ),
            const SizedBox(height: 8),
            const Text('수업 3회 / 매치 1회 참석'),
            const SizedBox(height: 24),

            // 📅 다가오는 일정
            Text('다가오는 일정', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Card(
              child: ListTile(
                leading: const Icon(Icons.class_, color: Colors.blue),
                title: const Text('[목 7/25] 수업 @구로풋살장 20:00'),
                subtitle: const Text('참석 12명'),
                onTap: () => Navigator.pushNamed(context, '/schedule'),
              ),
            ),
            Card(
              child: ListTile(
                leading: const Icon(Icons.sports_soccer, color: Colors.red),
                title: const Text('[일 7/28] 매치 vs 블루스타즈 18:00'),
                subtitle: const Text('참석 9명'),
                onTap: () => Navigator.pushNamed(context, '/schedule'),
              ),
            ),
            const SizedBox(height: 24),

            // 📢 최근 공지
            Text('최근 공지', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            const ListTile(
              leading: Icon(Icons.announcement),
              title: Text('7월 24일 구장 변경 안내'),
            ),
            const ListTile(
              leading: Icon(Icons.announcement),
              title: Text('MVP 투표 시작!'),
            ),
            const SizedBox(height: 24),

            // 🔗 빠른 액션
            Text('빠른 액션', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ElevatedButton.icon(
                  icon: const Icon(Icons.edit_calendar),
                  label: const Text('등록하기'),
                  onPressed: () => Navigator.pushNamed(context, '/classAdd'),
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.sports),
                  label: const Text('매치 등록'),
                  onPressed: () => Navigator.pushNamed(context, '/matchAdd'),
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.list_alt),
                  label: const Text('내 출석 보기'),
                  onPressed: () {},
                ),
              ],
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
