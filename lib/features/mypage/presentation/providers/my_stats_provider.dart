import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../matches/data/models/match_model.dart';
import '../../../matches/presentation/providers/match_providers.dart';
import '../../../teams/presentation/providers/current_team_provider.dart';

/// 최근 완료된 경기 목록
final recentFinishedMatchesProvider =
    StreamProvider<List<MatchModel>>((ref) {
  final teamId = ref.watch(currentTeamIdProvider);
  if (teamId == null) return const Stream.empty();

  return ref.watch(matchDataSourceProvider).watchRecentFinishedMatches(teamId);
});

/// 내 출석 통계
class MyAttendanceStats {
  const MyAttendanceStats({
    required this.total,
    required this.attended,
    required this.absent,
    required this.noVote,
  });

  final int total;
  final int attended;
  final int absent;
  final int noVote;

  double get attendanceRate => total > 0 ? attended / total : 0;
}

final myAttendanceStatsProvider =
    Provider.family<MyAttendanceStats, String?>((ref, uid) {
  if (uid == null) {
    return const MyAttendanceStats(
      total: 0,
      attended: 0,
      absent: 0,
      noVote: 0,
    );
  }

  final matches = ref.watch(recentFinishedMatchesProvider).value ?? [];
  int attended = 0;
  int absent = 0;
  int noVote = 0;

  for (final m in matches) {
    if (m.attendees?.contains(uid) ?? false) {
      attended++;
    } else if (m.absentees?.contains(uid) ?? false) {
      absent++;
    } else {
      noVote++;
    }
  }

  return MyAttendanceStats(
    total: matches.length,
    attended: attended,
    absent: absent,
    noVote: noVote,
  );
});
