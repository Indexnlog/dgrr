import 'package:cloud_firestore/cloud_firestore.dart';

class AdminMigrationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// ✅ 전체 컬렉션 마이그레이션 실행
  Future<void> migrateAllCollections() async {
    final collections = [
      'classes',
      'events',
      'feedbacks',
      'grounds',
      'lesson_fees',
      'match_media',
      'matches', // 하위 컬렉션 존재!
      'members',
      'membership_fees',
      'notifications',
      'polls',
      'posts',
      'registrations',
      'reservations',
      'settings',
      'transactions',
    ];

    for (final collection in collections) {
      if (collection == 'matches') {
        await _migrateMatchesWithRoundsAndRecords();
      } else {
        await _migrateSimpleCollection(collection);
      }
    }

    print('🎉 전체 컬렉션 마이그레이션 완료!');
  }

  /// ✅ 하위 컬렉션 없는 일반 컬렉션 마이그레이션
  Future<void> _migrateSimpleCollection(String collection) async {
    final snapshot = await _firestore.collection(collection).get();

    for (final doc in snapshot.docs) {
      final data = doc.data();
      final teamId = data['teamId'];

      if (teamId == null) {
        print('⚠️ teamId 없음: $collection/${doc.id}');
        continue;
      }

      final newDocRef = _firestore
          .collection('teams')
          .doc(teamId)
          .collection(collection)
          .doc(doc.id);

      await newDocRef.set(data);
      print('✅ migrated: $collection/${doc.id}');
    }
  }

  /// ✅ matches → rounds → records까지 재귀적으로 마이그레이션
  Future<void> _migrateMatchesWithRoundsAndRecords() async {
    final matchesSnapshot = await _firestore.collection('matches').get();

    for (final matchDoc in matchesSnapshot.docs) {
      final matchData = matchDoc.data();
      final teamId = matchData['teamId'];

      if (teamId == null) {
        print('⚠️ teamId 없음: matches/${matchDoc.id}');
        continue;
      }

      final matchRef = _firestore
          .collection('teams')
          .doc(teamId)
          .collection('matches')
          .doc(matchDoc.id);

      // ✅ 1. matches 상위 문서 복사
      await matchRef.set(matchData);
      print('✅ migrated match: ${matchDoc.id}');

      // ✅ 2. rounds 서브컬렉션 복사
      final roundsSnapshot = await _firestore
          .collection('matches')
          .doc(matchDoc.id)
          .collection('rounds')
          .get();

      for (final roundDoc in roundsSnapshot.docs) {
        final roundData = roundDoc.data();

        final roundRef = matchRef.collection('rounds').doc(roundDoc.id);
        await roundRef.set(roundData);
        print('  ↳ migrated round: ${roundDoc.id}');

        // ✅ 3. records 서브컬렉션 복사
        final recordsSnapshot = await _firestore
            .collection('matches')
            .doc(matchDoc.id)
            .collection('rounds')
            .doc(roundDoc.id)
            .collection('records')
            .get();

        for (final recordDoc in recordsSnapshot.docs) {
          final recordData = recordDoc.data();

          final recordRef = roundRef.collection('records').doc(recordDoc.id);
          await recordRef.set(recordData);
          print('    ↳ migrated record: ${recordDoc.id}');
        }
      }
    }
  }
}
