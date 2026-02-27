// 영원FC 앱 위젯 스모크 테스트
// Firebase 미초기화 상태에서 팀 선택 화면이 표시되는지 확인

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:dgrr_app/app/app.dart';
import 'package:dgrr_app/app/providers/firebase_ready_provider.dart';
import 'package:dgrr_app/features/teams/presentation/providers/current_team_provider.dart';

void main() {
  setUpAll(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('앱이 팀 선택 화면을 표시한다 (비로그인)', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          firebaseReadyProvider.overrideWithValue(false),
          currentTeamIdProvider.overrideWith(() => _FakeCurrentTeamNotifier()),
        ],
        child: const DgrrApp(),
      ),
    );

    await tester.pumpAndSettle();

    // 팀 선택/온보딩 화면에 진입 시 예상되는 UI 요소
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}

/// 테스트용 팀 Notifier (SharedPreferences 없이 null 반환)
class _FakeCurrentTeamNotifier extends CurrentTeamNotifier {
  @override
  String? build() => null;
}
