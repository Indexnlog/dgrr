import '../entities/reservation_notice.dart';

/// 예약 공지 날짜 계산 서비스
///
/// 규칙:
/// - 목요일 수업: 이용일 1달 전, 해당 주 월요일 23:58
/// - 일요일 매치: 이용일 1달 전, 해당 주 목요일 00:00
class ReservationNoticeService {
  /// 예약 시도 시점(openAt) 계산
  ///
  /// [targetDate]: 이용일
  /// [reservedForType]: class(목요일 수업) | match(일요일 매치)
  static DateTime calculateOpenAt(
    DateTime targetDate,
    ReservationNoticeForType reservedForType,
  ) {
    // 이용일 1달 전 (대략 28일)
    final oneMonthBefore = targetDate.subtract(const Duration(days: 28));

    switch (reservedForType) {
      case ReservationNoticeForType.class_:
        // 목요일 수업: 해당 주 월요일 23:58
        return _mondayOfWeek(oneMonthBefore)
            .add(const Duration(hours: 23, minutes: 58));
      case ReservationNoticeForType.match:
        // 일요일 매치: 목→금 넘어가는 00:00 (목요일 자정 = 금요일 00:00)
        return _thursdayOfWeek(oneMonthBefore)
            .add(const Duration(days: 1));
    }
  }

  /// 해당 주의 월요일 00:00
  static DateTime _mondayOfWeek(DateTime date) {
    final weekday = date.weekday;
    final daysToMonday = weekday - DateTime.monday;
    final monday = date.subtract(Duration(days: daysToMonday));
    return DateTime(monday.year, monday.month, monday.day);
  }

  /// 해당 주의 목요일 00:00
  static DateTime _thursdayOfWeek(DateTime date) {
    final weekday = date.weekday;
    const thursday = 4;
    final daysToThursday = weekday - thursday;
    final thursdayDate = date.subtract(Duration(days: daysToThursday));
    return DateTime(thursdayDate.year, thursdayDate.month, thursdayDate.day);
  }

  /// openAt을 사람이 읽기 쉬운 문자열로 (예: "월(2/23)에서 화(2/24) 23:58")
  static String formatOpenAt(DateTime openAt) {
    final nextDay = openAt.add(const Duration(minutes: 2));
    final m = openAt.month;
    final d = openAt.day;
    final m2 = nextDay.month;
    final d2 = nextDay.day;
    const weekdays = ['월', '화', '수', '목', '금', '토', '일'];
    final w1 = weekdays[openAt.weekday - 1];
    final w2 = weekdays[nextDay.weekday - 1];
    return '$w1($m/$d)에서 $w2($m2/$d2) 23:58~59';
  }
}
