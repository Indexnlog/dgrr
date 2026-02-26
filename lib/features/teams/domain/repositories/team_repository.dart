/// 팀 관련 Repository 인터페이스
abstract class TeamRepository {
  /// 팀 가입 신청 (멤버 생성, status: 'pending')
  Future<void> requestJoinTeam({
    required String teamId,
    required String userId,
  });
}
