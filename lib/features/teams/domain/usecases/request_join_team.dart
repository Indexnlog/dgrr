import '../repositories/team_repository.dart';

/// 팀 가입 신청 UseCase
class RequestJoinTeam {
  RequestJoinTeam(this.repository);

  final TeamRepository repository;

  Future<void> call({
    required String teamId,
    required String userId,
  }) {
    return repository.requestJoinTeam(
      teamId: teamId,
      userId: userId,
    );
  }
}
