import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../teams/presentation/providers/current_team_provider.dart';
import '../../data/datasources/poll_remote_data_source.dart';
import '../../data/models/poll_model.dart';
import 'poll_providers.dart';

class PollPagingState {
  const PollPagingState({
    this.polls = const [],
    this.lastDoc,
    this.hasMore = true,
    this.isLoading = false,
    this.isLoadingMore = false,
    this.error,
  });

  final List<PollModel> polls;
  final QueryDocumentSnapshot<Map<String, dynamic>>? lastDoc;
  final bool hasMore;
  final bool isLoading;
  final bool isLoadingMore;
  final Object? error;

  PollPagingState copyWith({
    List<PollModel>? polls,
    QueryDocumentSnapshot<Map<String, dynamic>>? lastDoc,
    bool? hasMore,
    bool? isLoading,
    bool? isLoadingMore,
    Object? error,
  }) {
    return PollPagingState(
      polls: polls ?? this.polls,
      lastDoc: lastDoc ?? this.lastDoc,
      hasMore: hasMore ?? this.hasMore,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      error: error,
    );
  }
}

final pollPagingProvider =
    NotifierProvider.autoDispose<PollPagingNotifier, PollPagingState>(
  PollPagingNotifier.new,
);

class PollPagingNotifier extends Notifier<PollPagingState> {
  static const int _pageSize = 20;

  PollRemoteDataSource get _ds => ref.read(pollDataSourceProvider);

  String? get _teamId => ref.read(currentTeamIdProvider);

  @override
  PollPagingState build() {
    // build() 내부에서 state를 읽으면 초기화 전 접근이 될 수 있어
    // 최초 로딩은 마이크로태스크로 미뤄서 안전하게 실행한다.
    Future.microtask(_loadInitial);
    return const PollPagingState(isLoading: true);
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
      final page = await _ds.fetchPollsPage(
        teamId,
        startAfter: state.lastDoc,
        limit: _pageSize,
      );

      final existingIds = state.polls.map((e) => e.pollId).toSet();
      final next = <PollModel>[
        ...state.polls,
        ...page.polls.where((p) => existingIds.add(p.pollId)),
      ];

      state = state.copyWith(
        polls: next,
        lastDoc: page.lastDoc,
        hasMore: page.hasMore && page.polls.isNotEmpty,
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
        polls: const [],
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
      polls: const [],
      lastDoc: null,
      hasMore: true,
    );

    try {
      final page = await _ds.fetchPollsPage(teamId, limit: _pageSize);
      state = state.copyWith(
        polls: page.polls,
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

