import 'package:flutter_test/flutter_test.dart';

import 'package:dgrr_app/features/matches/domain/entities/match.dart';

void main() {
  group('Match', () {
    test('effectiveMinPlayers defaults to 7', () {
      const match = Match(matchId: 'm1');
      expect(match.effectiveMinPlayers, 7);
    });

    test('effectiveLineupSize defaults to 5', () {
      const match = Match(matchId: 'm1');
      expect(match.effectiveLineupSize, 5);
    });

    test('hasEnoughPlayers when attendees >= minPlayers', () {
      const match = Match(
        matchId: 'm1',
        minPlayers: 7,
        attendees: ['a', 'b', 'c', 'd', 'e', 'f', 'g'],
      );
      expect(match.hasEnoughPlayers, true);
    });

    test('hasEnoughPlayers when attendees < minPlayers', () {
      const match = Match(
        matchId: 'm1',
        minPlayers: 7,
        attendees: ['a', 'b', 'c'],
      );
      expect(match.hasEnoughPlayers, false);
    });

    test('opponentName returns opponent.name when set', () {
      const match = Match(
        matchId: 'm1',
        opponent: OpponentInfo(name: '스마일리'),
      );
      expect(match.opponentName, '스마일리');
    });
  });
}
