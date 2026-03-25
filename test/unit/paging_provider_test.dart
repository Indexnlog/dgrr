import 'package:dgrr_app/features/matches/presentation/providers/match_paging_provider.dart';
import 'package:dgrr_app/features/polls/presentation/providers/poll_paging_provider.dart';
import 'package:dgrr_app/features/teams/presentation/providers/current_team_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('pollPagingProvider: teamId 없으면 로딩 없이 종료된다', () async {
    final container = ProviderContainer(
      overrides: [
        currentTeamIdProvider.overrideWith(() => _FakeCurrentTeamId()),
      ],
    );
    addTearDown(container.dispose);

    // autoDispose라서 read만 하면 바로 dispose될 수 있어 listen으로 유지한다
    final sub = container.listen(pollPagingProvider, (_, __) {});
    addTearDown(sub.close);
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);

    final state = container.read(pollPagingProvider);
    expect(state.isLoading, false);
    expect(state.polls, isEmpty);
    expect(state.hasMore, false);
  });

  test('matchPagingProvider: teamId 없으면 로딩 없이 종료된다', () async {
    final container = ProviderContainer(
      overrides: [
        currentTeamIdProvider.overrideWith(() => _FakeCurrentTeamId()),
      ],
    );
    addTearDown(container.dispose);

    final sub = container.listen(matchPagingProvider, (_, __) {});
    addTearDown(sub.close);
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);

    final state = container.read(matchPagingProvider);
    expect(state.isLoading, false);
    expect(state.matches, isEmpty);
    expect(state.hasMore, false);
  });
}

class _FakeCurrentTeamId extends CurrentTeamNotifier {
  @override
  String? build() => null;
}

