import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/public_team_model.dart';

class TeamsPublicRemoteDataSource {
  TeamsPublicRemoteDataSource(this.firestore);

  final FirebaseFirestore firestore;

  Stream<List<PublicTeamModel>> watchTeams() {
    return firestore.collection('teams_public').snapshots().map(
      (snapshot) {
        return snapshot.docs
            .map((doc) => PublicTeamModel.fromFirestore(doc.id, doc.data()))
            .toList();
      },
    );
  }
}
