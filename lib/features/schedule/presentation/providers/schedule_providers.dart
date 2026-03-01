import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_state_provider.dart';
import '../../../events/data/models/event_model.dart';
import '../../../events/domain/entities/event.dart';
import '../../../events/presentation/providers/event_providers.dart';
import '../../../matches/data/models/match_model.dart';
import '../../../matches/domain/entities/match.dart';
import '../../../matches/presentation/providers/match_providers.dart';
import '../../../teams/presentation/providers/current_team_provider.dart';

/// 캘린더에서 현재 포커스된 월
class FocusedMonthNotifier extends Notifier<DateTime> {
  @override
  DateTime build() {
    final now = DateTime.now();
    return DateTime(now.year, now.month);
  }

  void update(DateTime month) => state = month;
}

final focusedMonthProvider =
    NotifierProvider<FocusedMonthNotifier, DateTime>(FocusedMonthNotifier.new);

/// 캘린더에서 선택된 날짜
class SelectedDateNotifier extends Notifier<DateTime> {
  @override
  DateTime build() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  void update(DateTime date) => state = date;
}

final selectedDateProvider =
    NotifierProvider<SelectedDateNotifier, DateTime>(SelectedDateNotifier.new);

/// 포커스 월 기준 매치 목록 (전후 1주 여유 포함)
final monthlyMatchesProvider = StreamProvider<List<MatchModel>>((ref) {
  final teamId = ref.watch(currentTeamIdProvider);
  if (teamId == null) return const Stream.empty();

  final focusedMonth = ref.watch(focusedMonthProvider);
  final start = DateTime(focusedMonth.year, focusedMonth.month - 1, 25);
  final end = DateTime(focusedMonth.year, focusedMonth.month + 1, 7);

  return ref.watch(matchDataSourceProvider).watchMatchesInRange(
        teamId,
        start,
        end,
      );
});

/// 포커스 월 기준 수업 목록
final monthlyClassesForCalendarProvider =
    StreamProvider<List<EventModel>>((ref) {
  final teamId = ref.watch(currentTeamIdProvider);
  if (teamId == null) return const Stream.empty();

  final focusedMonth = ref.watch(focusedMonthProvider);
  return ref.watch(eventDataSourceProvider).watchClassesInRange(
        teamId,
        _dateStr(DateTime(focusedMonth.year, focusedMonth.month - 1, 25)),
        _dateStr(DateTime(focusedMonth.year, focusedMonth.month + 1, 7)),
      );
});

String _dateStr(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

/// 캘린더 마커용 통합 일정 아이템
/// [isUserParticipating] true=참여, false=비참여, null=미투표
class ScheduleItem {
  const ScheduleItem({
    required this.type,
    this.match,
    this.event,
    this.isUserParticipating,
  });
  final String type; // 'match' | 'class'
  final Match? match;
  final Event? event;
  final bool? isUserParticipating;

  String get id =>
      type == 'match' ? match!.matchId : event!.eventId;
}

/// 날짜 → 통합 일정 맵 (매치 + 수업, 참여 여부 포함)
final scheduleByDateProvider =
    Provider<Map<DateTime, List<ScheduleItem>>>((ref) {
  final matches = ref.watch(monthlyMatchesProvider).value ?? [];
  final classes = ref.watch(monthlyClassesForCalendarProvider).value ?? [];
  final uid = ref.watch(currentUserProvider)?.uid;
  final map = <DateTime, List<ScheduleItem>>{};

  for (final m in matches) {
    if (m.date == null) continue;
    final key = DateUtils.dateOnly(m.date!);
    final isParticipating =
        uid != null && (m.attendees?.contains(uid) ?? false);
    map.putIfAbsent(key, () => []).add(ScheduleItem(
          type: 'match',
          match: m,
          isUserParticipating: isParticipating,
        ));
  }

  for (final c in classes) {
    if (c.date == null) continue;
    final parts = c.date!.split('-');
    if (parts.length != 3) continue;
    final dt = DateTime(
      int.parse(parts[0]),
      int.parse(parts[1]),
      int.parse(parts[2]),
    );
    final key = DateUtils.dateOnly(dt);
    bool? isParticipating;
    if (uid != null && (c.attendees?.isNotEmpty ?? false)) {
      final myAttendee =
          c.attendees!.where((a) => a.userId == uid).firstOrNull;
      isParticipating = myAttendee != null &&
          (myAttendee.status == AttendeeStatus.attending ||
              myAttendee.status == AttendeeStatus.late ||
              myAttendee.status == AttendeeStatus.attended);
    }
    map.putIfAbsent(key, () => []).add(ScheduleItem(
          type: 'class',
          event: c,
          isUserParticipating: isParticipating,
        ));
  }

  return map;
});

/// 선택된 날짜의 통합 일정
final selectedDateScheduleProvider = Provider<List<ScheduleItem>>((ref) {
  final selected = ref.watch(selectedDateProvider);
  final key = DateUtils.dateOnly(selected);
  final map = ref.watch(scheduleByDateProvider);
  return map[key] ?? [];
});
