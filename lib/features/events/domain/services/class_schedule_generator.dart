import 'package:intl/intl.dart';

import '../../../../core/utils/korean_holidays.dart';

/// 월별 수업 일정 생성 (매주 목요일 + 예외 처리)
/// - 공휴일 제외 옵션
/// - 5번째 주 포함/제외 옵션
class ClassScheduleGenerator {
  ClassScheduleGenerator._();

  /// 해당 월의 모든 목요일 반환 (1=월요일, 4=목요일)
  static List<DateTime> thursdaysInMonth(int year, int month) {
    final result = <DateTime>[];
    final first = DateTime(year, month, 1);
    final last = DateTime(year, month + 1, 0);

    var d = first;
    while (d.weekday != DateTime.thursday) {
      d = d.add(const Duration(days: 1));
    }
    while (d.isBefore(last) || d.isAtSameMomentAs(last)) {
      result.add(d);
      d = d.add(const Duration(days: 7));
    }
    return result;
  }

  /// 5번째 목요일인지 확인
  static bool isFifthThursday(DateTime date, int year, int month) {
    final thursdays = thursdaysInMonth(year, month);
    return thursdays.length >= 5 && thursdays[4].day == date.day;
  }

  /// 수업 일정 후보 생성
  /// [excludeHolidays] 공휴일 제외
  /// [includeFifthWeek] 5번째 주(5번째 목요일) 포함
  static List<DateTime> generate({
    required int year,
    required int month,
    bool excludeHolidays = true,
    bool includeFifthWeek = true,
  }) {
    var dates = thursdaysInMonth(year, month);

    if (excludeHolidays) {
      dates = dates.where((d) => !KoreanHolidays.isHoliday(d)).toList();
    }

    if (!includeFifthWeek && dates.length >= 5) {
      dates = dates.where((d) => !isFifthThursday(d, year, month)).toList();
    }

    return dates;
  }

  /// yyyy-MM-dd 문자열 리스트로 변환
  static List<String> toDateStrings(List<DateTime> dates) {
    return dates.map((d) => DateFormat('yyyy-MM-dd').format(d)).toList();
  }
}
