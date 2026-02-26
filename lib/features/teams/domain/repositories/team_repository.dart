/// 팀 관련 Repository 인터페이스
abstract class TeamRepository {
  /// 팀 가입 신청 (멤버 생성, status: 'pending')
  Future<void> requestJoinTeam({
    required String teamId,
    required String userId,
  });

  /// 멤버 프로필 사진 URL 업데이트
  Future<void> updateMemberPhotoUrl({
    required String teamId,
    required String memberId,
    required String photoUrl,
  });
}
