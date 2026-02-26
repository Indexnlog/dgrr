import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/telegram/match_notification_service.dart';
import '../../../teams/presentation/providers/current_team_provider.dart';
import '../../data/datasources/match_remote_data_source.dart';
import '../../data/models/match_model.dart';
import '../../domain/entities/match.dart';

/// MatchRemoteDataSource Provider
final matchDataSourceProvider = Provider<MatchRemoteDataSource>((ref) {
  return MatchRemoteDataSource(firestore: FirebaseFirestore.instance);
});

/// Telegram 알림 서비스 Provider
final matchNotificationProvider = Provider<MatchNotificationService>((ref) {
  return MatchNotificationService();
});

/// 다가오는 경기 목록 실시간 스트림
final upcomingMatchesProvider = StreamProvider<List<MatchModel>>((ref) {
  final teamId = ref.watch(currentTeamIdProvider);
  if (teamId == null) return const Stream.empty();

  final ds = ref.watch(matchDataSourceProvider);
  return ds.watchUpcomingMatches(teamId);
});

/// 오늘 경기 개수 (매치 탭 배지용)
final todayMatchCountProvider = Provider<int>((ref) {
  final matches = ref.watch(upcomingMatchesProvider).value ?? [];
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  return matches.where((m) {
    if (m.date == null) return false;
    final d = m.date!;
    return d.year == today.year && d.month == today.month && d.day == today.day;
  }).length;
});

/// 참석 투표 (트랜잭션 + 성사 시 Telegram 알림)
Future<void> voteAttend(
  WidgetRef ref,
  Match match,
  String uid,
) async {
  final teamId = ref.read(currentTeamIdProvider);
  if (teamId == null) return;

  final result = await ref
      .read(matchDataSourceProvider)
      .voteAttend(teamId, match.matchId, uid);

  // 성사 전환 시 Telegram 알림
  if (result.didBecomeFixed && match.date != null) {
    final notifier = ref.read(matchNotificationProvider);
    await notifier.notifyMatchFixed(
      matchDate: match.date!,
      currentCount: result.attendeeCount,
      minPlayers: result.minPlayers,
      opponentName: match.opponentName,
      location: match.location,
    );
  }
}

/// 불참 투표 (트랜잭션 + 취소 위기 시 Telegram 알림)
Future<void> voteAbsent(
  WidgetRef ref,
  Match match,
  String uid,
) async {
  final teamId = ref.read(currentTeamIdProvider);
  if (teamId == null) return;

  final result = await ref
      .read(matchDataSourceProvider)
      .voteAbsent(teamId, match.matchId, uid);

  // 취소 위기 시 Telegram 알림
  if (result.didLoseQuorum && match.date != null) {
    final notifier = ref.read(matchNotificationProvider);
    await notifier.notifyMatchAtRisk(
      matchDate: match.date!,
      currentCount: result.attendeeCount,
      minPlayers: result.minPlayers,
      opponentName: match.opponentName,
    );
  }
}

/// 불참 투표 + 사유 (당일 변경 시)
Future<void> voteAbsentWithReason(
  WidgetRef ref,
  Match match,
  String uid,
  String reason,
) async {
  final teamId = ref.read(currentTeamIdProvider);
  if (teamId == null) return;

  final result = await ref
      .read(matchDataSourceProvider)
      .voteAbsentWithReason(teamId, match.matchId, uid, reason);

  if (result.didLoseQuorum && match.date != null) {
    final notifier = ref.read(matchNotificationProvider);
    await notifier.notifyMatchAtRisk(
      matchDate: match.date!,
      currentCount: result.attendeeCount,
      minPlayers: result.minPlayers,
      opponentName: match.opponentName,
    );
  }
}

/// 샘플 경기 데이터 삽입 (에뮬레이터 테스트용)
Future<void> seedSampleMatch(WidgetRef ref) async {
  final teamId = ref.read(currentTeamIdProvider);
  if (teamId == null) return;
  await ref.read(matchDataSourceProvider).seedSampleMatch(teamId);
}
