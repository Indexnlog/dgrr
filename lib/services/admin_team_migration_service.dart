import 'package:cloud_firestore/cloud_firestore.dart';

class AdminTeamMigrationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> migrateTeamToNamedId({
    required String oldId,
    required String newId,
  }) async {
    final oldTeamRef = _firestore.collection('teams').doc(oldId);
    final newTeamRef = _firestore.collection('teams').doc(newId);

    // ✅ 1. 상위 문서 복사
    final oldDoc = await oldTeamRef.get();
    if (!oldDoc.exists) {
      print('❌ 기존 팀 문서 없음: teams/$oldId');
      return;
    }

    final teamData = oldDoc.data()!;
    teamData['teamId'] = newId;
    await newTeamRef.set(teamData);
    print('✅ 상위 문서 복사 완료: teams/$oldId → teams/$newId');

    // ✅ 2. 하위 컬렉션들 복사
    final subCollections = [
      'classes',
      'events',
      'feedbacks',
      'grounds',
      'lesson_fees',
      'match_media',
      'matches',
      'members',
      'membership_fees',
      'notifications',
      'polls',
      'posts', // ✅ posts도 포함
      'registrations',
      'reservations',
      'settings',
      'transactions',
    ];

    for (final colName in subCollections) {
      final docs = await oldTeamRef.collection(colName).get();

      for (final doc in docs.docs) {
        final data = doc.data();
        data['teamId'] = newId; // ✅ teamId 덮어쓰기

        if (colName == 'matches') {
          final newMatchRef = newTeamRef.collection('matches').doc(doc.id);
          await newMatchRef.set(data);
          print('📁 matches 복사됨: ${doc.id}');

          final roundsSnapshot = await oldTeamRef
              .collection('matches')
              .doc(doc.id)
              .collection('rounds')
              .get();

          for (final roundDoc in roundsSnapshot.docs) {
            final roundData = roundDoc.data();
            roundData['teamId'] = newId; // ✅ teamId 덮어쓰기

            final newRoundRef = newMatchRef
                .collection('rounds')
                .doc(roundDoc.id);
            await newRoundRef.set(roundData);
            print('🔁 rounds 복사됨: ${roundDoc.id}');

            final recordsSnapshot = await oldTeamRef
                .collection('matches')
                .doc(doc.id)
                .collection('rounds')
                .doc(roundDoc.id)
                .collection('records')
                .get();

            for (final record in recordsSnapshot.docs) {
              final recordData = record.data();
              recordData['teamId'] = newId; // ✅ teamId 덮어쓰기

              await newRoundRef
                  .collection('records')
                  .doc(record.id)
                  .set(recordData);

              print('📝 records 복사됨: ${record.id}');
            }
          }
        } else {
          await newTeamRef.collection(colName).doc(doc.id).set(data);
          print('📁 복사됨: teams/$newId/$colName/${doc.id}');
        }
      }
    }

    print('🎉 모든 팀 데이터 복사 완료! teamId → $newId 로 갱신됨');
  }
}
