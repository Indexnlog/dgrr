/// 예약 시도 날짜 자동 계산 유틸리티 (순수 Dart)
///
/// 규칙:
/// - 목요일 수업: targetDate - 1개월 해당 주의 월요일 23:58 (= 화요일 00:00 직전)
/// - 일요일 매치: targetDate - 1개월 해당 주의 목요일 23:58 (= 금요일 00:00 직전)
class ReservationDateCalculator {
  ReservationDateCalculator._();

  /// 예약 시도 시각 계산
  ///
  /// [targetDate]: 이용일
  /// [isClass]: true=목요일 수업, false=일요일 매치
  static DateTime calculateReservationOpenTime(
    DateTime targetDate,
    bool isClass,
  ) {
    final oneMonthBefore = targetDate.subtract(const Duration(days: 28));

    if (isClass) {
      // 목요일 수업: 해당 주 월요일 23:58
      return _mondayOfWeek(oneMonthBefore)
          .add(const Duration(hours: 23, minutes: 58));
    } else {
      // 일요일 매치: 목→금 넘어가는 00:00
      return _thursdayOfWeek(oneMonthBefore)
          .add(const Duration(days: 1));
    }
  }

  static DateTime _mondayOfWeek(DateTime date) {
    final daysToMonday = date.weekday - DateTime.monday;
    final monday = date.subtract(Duration(days: daysToMonday));
    return DateTime(monday.year, monday.month, monday.day);
  }

  static DateTime _thursdayOfWeek(DateTime date) {
    const thursday = 4;
    final daysToThursday = date.weekday - thursday;
    final thursdayDate = date.subtract(Duration(days: daysToThursday));
    return DateTime(thursdayDate.year, thursdayDate.month, thursdayDate.day);
  }
}
