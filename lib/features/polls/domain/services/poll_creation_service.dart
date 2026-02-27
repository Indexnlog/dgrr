import 'package:intl/intl.dart';

import '../entities/poll.dart';
import '../../data/models/poll_model.dart';

/// 월별 등록 / 일자별 참석 투표 생성 헬퍼
class PollCreationService {
  PollCreationService._();

  /// 월별 등록 여부 투표 옵션 (20~24일)
  /// 옵션 id는 MembershipStatus.value와 일치해야 함
  static List<PollOption> membershipPollOptions() {
    return [
      PollOption(
        id: 'registered',
        text: '등록 (월 5만원) · 수업/경기 참가',
        voteCount: 0,
        votes: [],
      ),
      PollOption(
        id: 'paused',
        text: '휴회 (월 2만원) · 개인 사유 불참, 회원 자격 유지',
        voteCount: 0,
        votes: [],
      ),
      PollOption(
        id: 'exempt',
        text: '미등록(인정사유) (0원) · 부상·출산 등 팀 인정 사유',
        voteCount: 0,
        votes: [],
      ),
    ];
  }

  /// 월별 등록 투표 생성용 PollModel
  /// targetMonth: yyyy-MM (다음 달)
  /// 기간: 해당 월 20일 00:00 ~ 24일 23:59
  static PollModel createMembershipPoll({
    required String targetMonth,
    required String createdBy,
  }) {
    final parts = targetMonth.split('-');
    final year = int.tryParse(parts[0]) ?? DateTime.now().year;
    final month = int.tryParse(parts[1]) ?? DateTime.now().month;
    final startAt = DateTime(year, month - 1, 20); // 전월 20일
    final endAt = DateTime(year, month - 1, 24, 23, 59, 59); // 전월 24일

    final monthLabel = DateFormat('M월', 'ko_KR').format(DateTime(year, month));

    return PollModel(
      pollId: '',
      title: '${year}년 $monthLabel 등록 여부 투표',
      description:
          '다음 달 등록/휴회/미등록(인정사유) 중 선택해 주세요. 기간: 매월 20일~24일',
      type: PollType.option,
      category: PollCategory.membership,
      targetMonth: targetMonth,
      anonymous: false,
      canChangeVote: true,
      maxSelections: 1,
      showResultBeforeDeadline: true,
      isActive: true,
      expiresAt: endAt,
      createdBy: createdBy,
      createdAt: DateTime.now(),
      options: membershipPollOptions(),
    );
  }

  /// 일자별 참석 여부 투표용 옵션 생성
  /// classDates: 해당 월 수업 일자 리스트 (yyyy-MM-dd)
  static List<PollOption> attendancePollOptions(
    List<String> classDates,
  ) {
    return classDates.map((d) {
      final dt = DateTime.tryParse(d);
      final label = dt != null
          ? DateFormat('M/d (E)', 'ko_KR').format(dt)
          : d;
      return PollOption(
        id: d,
        text: label,
        date: dt,
        voteCount: 0,
        votes: [],
      );
    }).toList();
  }

  /// 일자별 참석 투표 생성용 PollModel
  /// targetMonth: yyyy-MM
  /// 기간: 해당 월 25일 00:00 ~ 말일 23:59
  static PollModel createAttendancePoll({
    required String targetMonth,
    required List<String> classDates,
    required String createdBy,
  }) {
    final parts = targetMonth.split('-');
    final year = int.tryParse(parts[0]) ?? DateTime.now().year;
    final month = int.tryParse(parts[1]) ?? DateTime.now().month;
    final startAt = DateTime(year, month - 1, 25); // 전월 25일
    final lastDay = DateTime(year, month, 0).day;
    final endAt = DateTime(year, month - 1, lastDay, 23, 59, 59);

    final monthLabel = DateFormat('M월', 'ko_KR').format(DateTime(year, month));

    return PollModel(
      pollId: '',
      title: '${year}년 $monthLabel 수업 참석 일자 투표',
      description:
          '해당 월 수업 일정 중 참석 가능한 날짜를 체크해 주세요. 코치님께서 수업 구성에 활용합니다. 기간: 매월 25일~말일',
      type: PollType.date,
      category: PollCategory.attendance,
      targetMonth: targetMonth,
      anonymous: false,
      canChangeVote: true,
      maxSelections: classDates.length,
      showResultBeforeDeadline: true,
      isActive: true,
      expiresAt: endAt,
      createdBy: createdBy,
      createdAt: DateTime.now(),
      options: attendancePollOptions(classDates),
    );
  }

  /// 다음 달 yyyy-MM 반환
  static String nextMonth() {
    final now = DateTime.now();
    final next = DateTime(now.year, now.month + 1);
    return '${next.year}-${next.month.toString().padLeft(2, '0')}';
  }

  /// 현재 달 yyyy-MM 반환
  static String currentMonth() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}';
  }
}
