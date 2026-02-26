import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../teams/presentation/providers/current_team_provider.dart';
import '../../data/datasources/reservation_remote_data_source.dart';
import '../../data/models/reservation_model.dart';

final reservationDataSourceProvider =
    Provider<ReservationRemoteDataSource>((ref) {
  return ReservationRemoteDataSource(firestore: FirebaseFirestore.instance);
});

final upcomingReservationsProvider =
    StreamProvider<List<ReservationModel>>((ref) {
  final teamId = ref.watch(currentTeamIdProvider);
  if (teamId == null) return const Stream.empty();
  return ref
      .watch(reservationDataSourceProvider)
      .watchUpcomingReservations(teamId);
});
