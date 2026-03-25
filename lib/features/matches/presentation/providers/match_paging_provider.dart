import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../teams/presentation/providers/current_team_provider.dart';
import '../../data/datasources/match_remote_data_source.dart';
import '../../data/models/match_model.dart';
import 'match_providers.dart';

class MatchPagingState {
  const MatchPagingState({
    this.matches = const [],
    this.lastDoc,
    this.hasMore = true,
    this.isLoading = false,
    this.isLoadingMore = false,
    this.error,
  });

  final List<MatchModel> matches;
  final QueryDocumentSnapshot<Map<String, dynamic>>? lastDoc;
  final bool hasMore;
  final bool isLoading;
  final bool isLoadingMore;
  final Object? error;

  MatchPagingState copyWith({
    List<MatchModel>? matches,
    QueryDocumentSnapshot<Map<String, dynamic>>? lastDoc,
    bool? hasMore,
    bool? isLoading,
    bool? isLoadingMore,
    Object? error,
  }) {
    return MatchPagingState(
      matches: matches ?? this.matches,
      lastDoc: lastDoc ?? this.lastDoc,
      hasMore: hasMore ?? this.hasMore,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      error: error,
    );
  }
}

final matchPagingProvider =
    NotifierProvider.autoDispose<MatchPagingNotifier, MatchPagingState>(
  MatchPagingNotifier.new,
);

class MatchPagingNotifier extends Notifier<MatchPagingState> {
  static const int _pageSize = 20;

  MatchRemoteDataSource get _ds => ref.read(matchDataSourceProvider);

  String? get _teamId => ref.read(currentTeamIdProvider);

  DateTime get _todayStart {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  @override
  MatchPagingState build() {
    Future.microtask(_loadInitial);
    return const MatchPagingState(isLoading: true);
  }

  Future<void> refresh() => _loadInitial();

  Future<void> loadMore() async {
    if (state.isLoading ||
        state.isLoadingMore ||
        !state.hasMore ||
        state.lastDoc == null) {
      return;
    }

    final teamId = _teamId;
    if (teamId == null) {
      state = state.copyWith(hasMore: false);
      return;
    }

    state = state.copyWith(isLoadingMore: true, error: null);

    try {
      final page = await _ds.fetchUpcomingMatchesPage(
        teamId,
        todayStart: _todayStart,
        startAfter: state.lastDoc,
        limit: _pageSize,
      );

      final existingIds = state.matches.map((e) => e.matchId).toSet();
      final next = <MatchModel>[
        ...state.matches,
        ...page.matches.where((m) => existingIds.add(m.matchId)),
      ];

      state = state.copyWith(
        matches: next,
        lastDoc: page.lastDoc,
        hasMore: page.hasMore && page.matches.isNotEmpty,
      );
    } catch (e) {
      state = state.copyWith(error: e);
    } finally {
      state = state.copyWith(isLoadingMore: false);
    }
  }

  Future<void> _loadInitial() async {
    final teamId = _teamId;
    if (teamId == null) {
      state = state.copyWith(
        matches: const [],
        lastDoc: null,
        hasMore: false,
        isLoading: false,
        isLoadingMore: false,
      );
      return;
    }

    state = state.copyWith(
      isLoading: true,
      isLoadingMore: false,
      error: null,
      matches: const [],
      lastDoc: null,
      hasMore: true,
    );

    try {
      final page = await _ds.fetchUpcomingMatchesPage(
        teamId,
        todayStart: _todayStart,
        limit: _pageSize,
      );
      state = state.copyWith(
        matches: page.matches,
        lastDoc: page.lastDoc,
        hasMore: page.hasMore,
      );
    } catch (e) {
      state = state.copyWith(error: e);
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }
}

