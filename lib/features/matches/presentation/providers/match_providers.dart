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

/// 매치 탭 노출 조건: attendees >= 7 AND opponent.status == confirmed
/// (.cursorrules: 경기 카드는 성사된 경기만 표시)
bool _shouldShowMatchCard(MatchModel m) {
  final attendees = m.attendees?.length ?? 0;
  final minPlayers = m.effectiveMinPlayers;
  final opponentConfirmed = m.opponent?.isConfirmed == true;
  return attendees >= minPlayers && opponentConfirmed;
}

/// 다가오는 경기 목록 실시간 스트림 (성사된 경기만 표시)
/// autoDispose: 매치 탭 벗어나면 구독 해제
final upcomingMatchesProvider =
    StreamProvider.autoDispose<List<MatchModel>>((ref) {
  final teamId = ref.watch(currentTeamIdProvider);
  if (teamId == null) return const Stream.empty();

  final ds = ref.watch(matchDataSourceProvider);
  return ds.watchUpcomingMatches(teamId).map((list) =>
      list.where(_shouldShowMatchCard).toList());
});

/// 오늘 경기 또는 진행 중 경기 개수 (매치 탭 배지용)
final todayOrLiveMatchCountProvider = Provider<int>((ref) {
  final matches = ref.watch(upcomingMatchesProvider).value ?? [];
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  return matches.where((m) {
    // 진행 중 경기 포함
    if (m.gameStatus == GameStatus.playing) return true;
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

/// 지각 참석 투표 (참석 + 지각 예상 시간)
Future<void> voteAttendLate(
  WidgetRef ref,
  Match match,
  String uid,
  String lateTime,
) async {
  final teamId = ref.read(currentTeamIdProvider);
  if (teamId == null) return;

  final result = await ref
      .read(matchDataSourceProvider)
      .voteAttendLate(teamId, match.matchId, uid, lateTime);

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

/// 공 가져가기 자원 토글 ("저도 들고가요")
Future<void> toggleBallBringer(
  WidgetRef ref,
  Match match,
  String uid,
) async {
  final teamId = ref.read(currentTeamIdProvider);
  if (teamId == null) return;
  await ref
      .read(matchDataSourceProvider)
      .toggleBallBringer(teamId, match.matchId, uid);
}

/// 샘플 경기 데이터 삽입 (에뮬레이터 테스트용)
Future<void> seedSampleMatch(WidgetRef ref) async {
  final teamId = ref.read(currentTeamIdProvider);
  if (teamId == null) return;
  await ref.read(matchDataSourceProvider).seedSampleMatch(teamId);
}
