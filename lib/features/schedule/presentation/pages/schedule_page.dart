import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../../../core/theme/app_theme.dart';

import '../../../events/domain/entities/event.dart';
import '../../../matches/domain/entities/match.dart';
import '../../../reservations/presentation/providers/reservation_notice_providers.dart';
import '../providers/schedule_providers.dart';


class SchedulePage extends ConsumerWidget {
  const SchedulePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final focusedMonth = ref.watch(focusedMonthProvider);
    final selectedDate = ref.watch(selectedDateProvider);
    final scheduleByDate = ref.watch(scheduleByDateProvider);
    final selectedSchedule = ref.watch(selectedDateScheduleProvider);

    return Scaffold(
      backgroundColor: AppTheme.bgDeep,
      body: SafeArea(
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(child: _buildHeader(context, ref)),
            SliverToBoxAdapter(child: _buildCalendar(ref, focusedMonth, selectedDate, scheduleByDate)),
            const SliverToBoxAdapter(child: SizedBox(height: 16)),
            if (selectedSchedule.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: _buildEmpty(selectedDate),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final item = selectedSchedule[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: item.type == 'match'
                            ? _MatchScheduleCard(match: item.match!)
                            : _ClassScheduleCard(event: item.event!),
                      );
                    },
                    childCount: selectedSchedule.length,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, WidgetRef ref) {
    final noticesAsync = ref.watch(upcomingReservationNoticesProvider);
    final noticeCount = noticesAsync.value?.length ?? 0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(PhosphorIconsFill.calendar, color: AppTheme.teamRed, size: 22),
              const SizedBox(width: 10),
              const Text('일정',
                  style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5)),
              const Spacer(),
              GestureDetector(
                onTap: () => context.push('/schedule/reservation-notices'),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.fixedBlue.withValues(alpha:0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.fixedBlue.withValues(alpha:0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(PhosphorIconsRegular.calendarCheck, color: AppTheme.fixedBlue, size: 16),
                      const SizedBox(width: 6),
                      Text(
                        '예약 공지${noticeCount > 0 ? ' $noticeCount' : ''}',
                        style: const TextStyle(
                          color: AppTheme.fixedBlue,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => context.push('/schedule/polls'),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.attendGreen.withValues(alpha:0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.attendGreen.withValues(alpha:0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(PhosphorIconsRegular.listChecks, color: AppTheme.attendGreen, size: 16),
                      const SizedBox(width: 6),
                      Text(
                        '회비·출석 투표',
                        style: const TextStyle(
                          color: AppTheme.attendGreen,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _LegendDot(color: AppTheme.gold, label: '매치'),
              const SizedBox(width: 12),
              _LegendDot(color: AppTheme.classBlue, label: '수업'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCalendar(
    WidgetRef ref,
    DateTime focusedMonth,
    DateTime selectedDate,
    Map<DateTime, List<ScheduleItem>> scheduleByDate,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.divider),
      ),
      child: TableCalendar<ScheduleItem>(
        locale: 'ko_KR',
        firstDay: DateTime(2024, 1, 1),
        lastDay: DateTime(2030, 12, 31),
        focusedDay: focusedMonth,
        selectedDayPredicate: (day) => isSameDay(day, selectedDate),
        eventLoader: (day) {
          final key = DateUtils.dateOnly(day);
          return scheduleByDate[key] ?? [];
        },
        onDaySelected: (selected, focused) {
          ref.read(selectedDateProvider.notifier).update(selected);
          ref.read(focusedMonthProvider.notifier).update(focused);
        },
        onPageChanged: (focused) {
          ref.read(focusedMonthProvider.notifier).update(focused);
        },
        startingDayOfWeek: StartingDayOfWeek.monday,
        headerStyle: HeaderStyle(
          titleCentered: true,
          formatButtonVisible: false,
          titleTextStyle: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w700),
          leftChevronIcon:
              const Icon(Icons.chevron_left, color: AppTheme.textSecondary),
          rightChevronIcon:
              const Icon(Icons.chevron_right, color: AppTheme.textSecondary),
          headerPadding: const EdgeInsets.symmetric(vertical: 12),
        ),
        daysOfWeekStyle: DaysOfWeekStyle(
          weekdayStyle: TextStyle(
              color: AppTheme.textMuted, fontSize: 12, fontWeight: FontWeight.w600),
          weekendStyle: TextStyle(
              color: AppTheme.textMuted.withValues(alpha:0.7),
              fontSize: 12,
              fontWeight: FontWeight.w600),
        ),
        calendarStyle: CalendarStyle(
          outsideDaysVisible: false,
          cellMargin: const EdgeInsets.all(4),
          defaultTextStyle: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w500),
          weekendTextStyle: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 14,
              fontWeight: FontWeight.w500),
          // 오늘: 블루 테두리 (참고: 선택일 블루 강조)
          todayDecoration: BoxDecoration(
            color: AppTheme.fixedBlue.withValues(alpha: 0.15),
            shape: BoxShape.circle,
            border: Border.all(color: AppTheme.fixedBlue, width: 1.5),
          ),
          todayTextStyle: const TextStyle(
              color: AppTheme.fixedBlue, fontSize: 14, fontWeight: FontWeight.w700),
          // 선택일: 블루 채움 (참고 달력 포맷)
          selectedDecoration:
              const BoxDecoration(color: AppTheme.fixedBlue, shape: BoxShape.circle),
          selectedTextStyle: const TextStyle(
              color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700),
          markerSize: 6,
          markersMaxCount: 3,
          markerMargin: const EdgeInsets.symmetric(horizontal: 1),
        ),
        calendarBuilders: CalendarBuilders(
          // 이벤트 있는 날: 그린 서클 배경 (참고 달력 포맷)
          defaultBuilder: (context, day, focusedDay) {
            final key = DateUtils.dateOnly(day);
            final events = scheduleByDate[key] ?? [];
            final hasEvents = events.isNotEmpty;
            final isToday = isSameDay(day, DateTime.now());
            final isSelected = isSameDay(day, selectedDate);
            if (isToday || isSelected) return null; // 기본 렌더링 사용
            if (hasEvents) {
              return Center(
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppTheme.attendGreen.withValues(alpha: 0.25),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppTheme.attendGreen.withValues(alpha: 0.5),
                      width: 1,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      '${day.day}',
                      style: const TextStyle(
                        color: AppTheme.attendGreen,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              );
            }
            return null;
          },
          markerBuilder: (context, date, events) {
            if (events.isEmpty) return null;
            return Positioned(
              bottom: 4,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: events.take(3).map((item) {
                  final color = item.type == 'class'
                      ? AppTheme.classBlue
                      : _matchMarkerColor(item.match?.status);
                  return Container(
                    width: 6,
                    height: 6,
                    margin: const EdgeInsets.symmetric(horizontal: 1),
                    decoration:
                        BoxDecoration(shape: BoxShape.circle, color: color),
                  );
                }).toList(),
              ),
            );
          },
        ),
      ),
    );
  }

  Color _matchMarkerColor(MatchStatus? status) {
    return switch (status) {
      MatchStatus.fixed => AppTheme.fixedBlue,
      MatchStatus.confirmed => AppTheme.attendGreen,
      MatchStatus.inProgress => AppTheme.teamRed,
      MatchStatus.finished => AppTheme.textMuted,
      MatchStatus.cancelled => AppTheme.absentRed,
      _ => AppTheme.gold,
    };
  }

  Widget _buildEmpty(DateTime selectedDate) {
    final m = selectedDate.month;
    final d = selectedDate.day;
    final wd = _weekday(selectedDate.weekday);

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(PhosphorIconsRegular.calendarBlank,
              size: 48, color: AppTheme.textMuted.withValues(alpha: 0.4)),
          const SizedBox(height: 12),
          Text('$m월 $d일 ($wd)',
              style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text('예정된 일정이 없습니다',
              style: TextStyle(color: AppTheme.textMuted, fontSize: 13)),
        ],
      ),
    );
  }

  String _weekday(int wd) {
    const days = ['월', '화', '수', '목', '금', '토', '일'];
    return days[wd - 1];
  }
}

// ── 매치 카드 ──

class _MatchScheduleCard extends StatelessWidget {
  const _MatchScheduleCard({required this.match});
  final Match match;

  @override
  Widget build(BuildContext context) {
    final time = match.startTime ?? '--:--';
    final opponent = match.opponentName ?? '상대 미정';
    final location = match.location ?? '장소 미정';
    final attendCount = match.attendees?.length ?? 0;
    final minPlayers = match.effectiveMinPlayers;

    return GestureDetector(
      onTap: () => context.push('/match/${match.matchId}'),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.bgCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.divider),
        ),
        child: Row(
          children: [
            // 타입 표시
            Container(
              width: 4,
              height: 44,
              decoration: BoxDecoration(
                  color: AppTheme.gold, borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(width: 14),
            // 시간
            SizedBox(
              width: 50,
              child: Text(time,
                  style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w800)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('vs $opponent',
                      style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w700),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 3),
                  Text(location,
                      style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: attendCount >= minPlayers
                    ? AppTheme.attendGreen.withValues(alpha:0.12)
                    : AppTheme.surface,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text('$attendCount/$minPlayers',
                  style: TextStyle(
                      color: attendCount >= minPlayers
                          ? AppTheme.attendGreen
                          : AppTheme.textSecondary,
                      fontSize: 13,
                      fontWeight: FontWeight.w700)),
            ),
            const SizedBox(width: 4),
            Icon(Icons.chevron_right, size: 18, color: AppTheme.textMuted),
          ],
        ),
      ),
    );
  }
}

// ── 수업 카드 ──

class _ClassScheduleCard extends StatelessWidget {
  const _ClassScheduleCard({required this.event});
  final Event event;

  @override
  Widget build(BuildContext context) {
    final location = event.location ?? '장소 미정';
    final presentCount = event.attendance?.present ?? 0;
    final attendees = event.attendees ?? [];

    return GestureDetector(
      onTap: () => context.push('/schedule/class/${event.eventId}'),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.bgCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.divider),
        ),
        child: Row(
          children: [
            Container(
              width: 4,
              height: 44,
              decoration: BoxDecoration(
                  color: AppTheme.classBlue,
                  borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(width: 14),
            SizedBox(
              width: 50,
              child: Text(event.startTime ?? '--:--',
                  style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w800)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(event.title ?? '정기 수업',
                      style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w700),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 3),
                  Text(location,
                      style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.classBlue.withValues(alpha:0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                  attendees.isEmpty ? '0명' : '$presentCount명',
                  style: const TextStyle(
                      color: AppTheme.classBlue,
                      fontSize: 13,
                      fontWeight: FontWeight.w700)),
            ),
            const SizedBox(width: 4),
            Icon(Icons.chevron_right, size: 18, color: AppTheme.textMuted),
          ],
        ),
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
            width: 8,
            height: 8,
            decoration:
                BoxDecoration(shape: BoxShape.circle, color: color)),
        const SizedBox(width: 4),
        Text(label,
            style: TextStyle(
                color: AppTheme.textMuted,
                fontSize: 11,
                fontWeight: FontWeight.w500)),
      ],
    );
  }
}
