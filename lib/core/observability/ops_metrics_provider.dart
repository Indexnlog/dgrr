import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/teams/presentation/providers/current_team_provider.dart';

/// 일별 운영 메트릭 문서 provider
final todayOpsMetricsProvider =
    StreamProvider<Map<String, dynamic>?>((ref) {
  final teamId = ref.watch(currentTeamIdProvider);
  if (teamId == null) {
    return const Stream.empty();
  }

  final now = DateTime.now();
  final key =
      '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

  return FirebaseFirestore.instance
      .collection('teams')
      .doc(teamId)
      .collection('ops_metrics_daily')
      .doc(key)
      .snapshots()
      .map((doc) => doc.data());
});
