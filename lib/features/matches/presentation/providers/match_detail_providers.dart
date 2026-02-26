import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../teams/presentation/providers/current_team_provider.dart';
import '../../data/datasources/round_record_data_source.dart';
import '../../data/models/match_model.dart';
import '../../data/models/round_model.dart';
import '../../domain/entities/record.dart';

final roundRecordDataSourceProvider = Provider<RoundRecordDataSource>((ref) {
  return RoundRecordDataSource(firestore: FirebaseFirestore.instance);
});

/// 경기 상세 문서 스트림
final matchDetailProvider =
    StreamProvider.family<MatchModel?, String>((ref, matchId) {
  final teamId = ref.watch(currentTeamIdProvider);
  if (teamId == null) return Stream.value(null);

  return FirebaseFirestore.instance
      .collection('teams')
      .doc(teamId)
      .collection('matches')
      .doc(matchId)
      .snapshots()
      .map((snap) =>
          snap.exists ? MatchModel.fromFirestore(snap.id, snap.data()!) : null);
});

/// 경기 라운드 목록 스트림
final matchRoundsProvider =
    StreamProvider.family<List<RoundModel>, String>((ref, matchId) {
  final teamId = ref.watch(currentTeamIdProvider);
  final dataSource = ref.watch(roundRecordDataSourceProvider);
  if (teamId == null) return Stream.value([]);

  return dataSource.watchRounds(teamId, matchId);
});

/// 라운드별 기록 스트림
final roundRecordsProvider = StreamProvider.family<List<Record>,
    ({String matchId, String roundId})>((ref, params) {
  final teamId = ref.watch(currentTeamIdProvider);
  final dataSource = ref.watch(roundRecordDataSourceProvider);
  if (teamId == null) return Stream.value([]);

  return dataSource.watchRecords(teamId, params.matchId, params.roundId);
});

/// 현재 필드 선수 / 벤치 (라인업 + 교체 기록 반영)
class CurrentFieldResult {
  const CurrentFieldResult({required this.fieldUids, required this.benchUids});
  final List<String> fieldUids;
  final List<String> benchUids;
}

final currentFieldPlayersProvider = Provider.family<CurrentFieldResult?,
    ({String matchId, String roundId})>((ref, params) {
  final match = ref.watch(matchDetailProvider(params.matchId)).whenOrNull(data: (m) => m);
  final records = ref.watch(roundRecordsProvider(params)).whenOrNull(data: (r) => r);
  if (match == null || records == null) return null;

  final lineup = match.lineup ?? match.participants ?? match.attendees ?? [];
  if (lineup.isEmpty) return null;

  final size = match.effectiveLineupSize;
  var field = List<String>.from(lineup.take(size));
  final bench = List<String>.from(lineup.skip(size));

  final subs = records
      .whereType<SubstitutionRecord>()
      .where((r) => r.teamType == TeamType.our)
      .toList()
    ..sort((a, b) => a.timeOffset.compareTo(b.timeOffset));

  for (final s in subs) {
    final outId = s.outPlayerId;
    final inId = s.inPlayerId;
    if (outId != null && inId != null) {
      final idx = field.indexOf(outId);
      if (idx >= 0) {
        field = List.from(field)..[idx] = inId;
      }
    }
  }

  return CurrentFieldResult(fieldUids: field, benchUids: bench);
});
