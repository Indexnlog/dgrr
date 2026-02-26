import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/team_local_data_source.dart';

/// 현재 선택된 팀 ID를 관리하는 Notifier (Riverpod 3.x)
class CurrentTeamNotifier extends Notifier<String?> {
  late final TeamLocalDataSource _localDataSource;

  @override
  String? build() {
    _localDataSource = TeamLocalDataSource();
    _loadTeamId();
    return null;
  }

  Future<void> _loadTeamId() async {
    final teamId = await _localDataSource.getCurrentTeamId();
    state = teamId;
  }

  /// 팀 선택
  Future<void> selectTeam(String teamId) async {
    await _localDataSource.setCurrentTeamId(teamId);
    state = teamId;
  }

  /// 팀 선택 해제 (로그아웃 시)
  Future<void> clearTeam() async {
    await _localDataSource.clearCurrentTeamId();
    state = null;
  }
}

final currentTeamIdProvider =
    NotifierProvider<CurrentTeamNotifier, String?>(CurrentTeamNotifier.new);

/// 현재 팀이 선택되었는지 여부
final hasCurrentTeamProvider = Provider<bool>((ref) {
  return ref.watch(currentTeamIdProvider) != null;
});
