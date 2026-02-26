import 'package:shared_preferences/shared_preferences.dart';

/// 로컬 저장소에 현재 팀 ID 저장/조회
class TeamLocalDataSource {
  static const String _currentTeamIdKey = 'current_team_id';

  Future<String?> getCurrentTeamId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_currentTeamIdKey);
  }

  Future<void> setCurrentTeamId(String teamId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_currentTeamIdKey, teamId);
  }

  Future<void> clearCurrentTeamId() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_currentTeamIdKey);
  }
}
