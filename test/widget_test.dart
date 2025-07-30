import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/main.dart';

void main() {
  testWidgets('지구공 홈 화면이 정상적으로 표시된다', (WidgetTester tester) async {
    // 앱 실행
    await tester.pumpWidget(const MyApp());

    // 홈 탭의 제목이 존재하는지 확인
    expect(find.text('지구공 홈'), findsOneWidget);

    // 인사말 존재 여부 확인
    expect(find.textContaining('안녕하세요'), findsOneWidget);

    // 빠른 액션 버튼 중 하나가 있는지 확인
    expect(find.text('등록하기'), findsOneWidget);
  });

  testWidgets('하단 탭바에서 일정 탭으로 이동한다', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    // 일정 탭 아이콘 탭
    await tester.tap(find.byIcon(Icons.calendar_today));
    await tester.pumpAndSettle();

    // 탭 이동 후에 특정 텍스트가 있는지 검사 (SchedulePage에서 텍스트 넣어두면 됨)
    expect(
      find.text('일정'),
      findsOneWidget,
    ); // 예시: '일정'이라는 텍스트가 SchedulePage에 있다고 가정
  });
}
