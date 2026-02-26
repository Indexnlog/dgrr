import 'package:intl/intl.dart';

import '../../../events/data/models/event_model.dart';
import '../../../events/domain/entities/event.dart';
import '../../../teams/domain/entities/member.dart';
import '../entities/poll.dart';

/// 출석 투표 결과 → 수업 Event 일괄 생성
class PollToEventService {
  PollToEventService._();

  /// 날짜 형식(yyyy-MM-dd)인지 확인
  static bool _isDateOption(String optionId) {
    if (optionId.length != 10) return false;
    final parts = optionId.split('-');
    if (parts.length != 3) return false;
    final dt = DateTime.tryParse(optionId);
    return dt != null;
  }

  /// 출석 투표에서 수업 Event 목록 생성
  /// - date 옵션(id가 yyyy-MM-dd)만 대상
  /// - votes에 있는 uid를 attendees로 변환
  static List<EventModel> createEventsFromAttendancePoll({
    required Poll poll,
    required Map<String, Member> memberMap,
    required String createdBy,
    String defaultLocation = '금천구 풋살장',
    String defaultStartTime = '20:00',
    String defaultEndTime = '22:00',
  }) {
    if (poll.category != PollCategory.attendance) return [];
    final options = poll.options ?? [];
    final events = <EventModel>[];

    for (final opt in options) {
      if (!_isDateOption(opt.id)) continue;

      final attendees = <EventAttendeeModel>[];
      for (final uid in opt.votes ?? []) {
        final m = memberMap[uid];
        attendees.add(EventAttendeeModel(
          userId: uid,
          userName: m?.uniformName ?? m?.name,
          number: m?.number,
          status: AttendeeStatus.attending,
        ));
      }

      final dt = DateTime.tryParse(opt.id);
      final dateLabel = dt != null ? DateFormat('M/d (E)', 'ko_KR').format(dt) : opt.id;

      events.add(EventModel(
        eventId: '',
        type: EventType.class_,
        title: '${poll.targetMonth ?? ''} 수업 $dateLabel',
        date: opt.id,
        startTime: defaultStartTime,
        endTime: defaultEndTime,
        location: defaultLocation,
        status: EventStatus.active,
        fromPoll: true,
        pollId: poll.pollId,
        createdBy: createdBy,
        createdAt: DateTime.now(),
        attendees: attendees,
        attendance: AttendanceSummaryModel(
          present: attendees.length,
          absent: 0,
        ),
      ));
    }

    return events;
  }
}
