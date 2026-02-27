import 'package:flutter_test/flutter_test.dart';

import 'package:dgrr_app/features/opponents/domain/entities/opponent.dart';

void main() {
  group('OpponentRecords', () {
    test('total returns sum of wins, draws, losses', () {
      const rec = OpponentRecords(wins: 3, draws: 2, losses: 1);
      expect(rec.total, 6);
    });

    test('default values are 0', () {
      const rec = OpponentRecords();
      expect(rec.wins, 0);
      expect(rec.draws, 0);
      expect(rec.losses, 0);
      expect(rec.total, 0);
    });
  });
}
