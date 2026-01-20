import '../entities/public_team.dart';
import '../repositories/teams_public_repository.dart';

class WatchPublicTeams {
  WatchPublicTeams(this.repository);

  final TeamsPublicRepository repository;

  Stream<List<PublicTeam>> call() {
    return repository.watchTeams();
  }
}
