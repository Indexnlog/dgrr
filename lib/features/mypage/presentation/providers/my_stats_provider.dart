import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../events/domain/entities/event.dart';
import '../../../events/presentation/providers/event_providers.dart';
import '../../../matches/data/models/match_model.dart';
import '../../../matches/domain/entities/record.dart';
import '../../../matches/presentation/providers/match_detail_providers.dart';
import '../../../matches/presentation/providers/match_providers.dart';
import '../../../teams/presentation/providers/current_team_provider.dart';

/// 팀 합류 기간 포맷 (N일째 / N개월째)
String formatTenure(DateTime? joinedAt) {
  if (joinedAt == null) return '';
  final now = DateTime.now();
  final diff = now.difference(joinedAt);
  final days = diff.inDays;
  if (days < 30) return '${days}일째';
  final months = (days / 30).floor();
  if (months < 12) return '${months}개월째';
  final years = (months / 12).floor();
  return '${years}년째';
}

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

/// 수업 출석 통계
class MyClassStats {
  const MyClassStats({
    required this.total,
    required this.attended,
    required this.absent,
  });

  final int total;
  final int attended;
  final int absent;

  double get attendanceRate => total > 0 ? attended / total : 0;
}

final myClassStatsProvider =
    Provider.family<MyClassStats, String?>((ref, uid) {
  if (uid == null) {
    return const MyClassStats(total: 0, attended: 0, absent: 0);
  }

  final classes = ref.watch(recentFinishedClassesProvider).value ?? [];
  int attended = 0;
  int absent = 0;

  for (final c in classes) {
    final a = c.attendees?.where((a) => a.userId == uid).firstOrNull;
    if (a == null) continue;
    final status = a.status;
    if (status == AttendeeStatus.attended ||
        status == AttendeeStatus.attending ||
        status == AttendeeStatus.late) {
      attended++;
    } else if (status == AttendeeStatus.absent) {
      absent++;
    }
  }

  return MyClassStats(
    total: classes.length,
    attended: attended,
    absent: absent,
  );
});

/// 경기 활약 (골/도움)
class MyMatchPerformance {
  const MyMatchPerformance({
    required this.goals,
    required this.assists,
  });

  final int goals;
  final int assists;
}

final myMatchPerformanceProvider =
    FutureProvider.family<MyMatchPerformance, String?>((ref, uid) async {
  if (uid == null) return const MyMatchPerformance(goals: 0, assists: 0);

  final teamId = ref.watch(currentTeamIdProvider);
  if (teamId == null) return const MyMatchPerformance(goals: 0, assists: 0);

  final matches = ref.watch(recentFinishedMatchesProvider).value ?? [];
  final dataSource = ref.read(roundRecordDataSourceProvider);

  int goals = 0;
  int assists = 0;

  for (final m in matches) {
    final records = await dataSource.fetchAllRecordsForMatch(teamId, m.matchId);
    for (final r in records) {
      if (r is GoalRecord && r.teamType == TeamType.our && r.isOwnGoal != true) {
        if (r.playerId == uid) goals++;
        if (r.assistPlayerId == uid) assists++;
      }
    }
  }

  return MyMatchPerformance(goals: goals, assists: assists);
});
