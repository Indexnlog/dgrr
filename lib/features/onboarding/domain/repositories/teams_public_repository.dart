import '../entities/public_team.dart';

abstract class TeamsPublicRepository {
  Stream<List<PublicTeam>> watchTeams();
}
