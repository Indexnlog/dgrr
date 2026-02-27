/// 한국 공휴일 (2025~2026, 주요 휴일만)
/// 수업 일정 생성 시 제외 옵션용
class KoreanHolidays {
  KoreanHolidays._();

  static final _holidays2025 = [
    DateTime(2025, 1, 1),   // 신정
    DateTime(2025, 1, 28), DateTime(2025, 1, 29), DateTime(2025, 1, 30), // 설
    DateTime(2025, 3, 1),  // 삼일절
    DateTime(2025, 5, 5),  // 어린이날
    DateTime(2025, 5, 6),  // 대체휴일
    DateTime(2025, 6, 6),  // 현충일
    DateTime(2025, 8, 15), // 광복절
    DateTime(2025, 10, 3), // 개천절
    DateTime(2025, 10, 9), // 한글날
    DateTime(2025, 12, 25), // 크리스마스
    DateTime(2025, 2, 11), DateTime(2025, 2, 12), // 설 연휴
    DateTime(2025, 9, 5), DateTime(2025, 9, 6), DateTime(2025, 9, 7), // 추석
  ];

  static final _holidays2026 = [
    DateTime(2026, 1, 1),
    DateTime(2026, 2, 16), DateTime(2026, 2, 17), DateTime(2026, 2, 18), // 설
    DateTime(2026, 3, 1),
    DateTime(2026, 5, 5),
    DateTime(2026, 6, 6),
    DateTime(2026, 8, 15),
    DateTime(2026, 9, 24), DateTime(2026, 9, 25), DateTime(2026, 9, 26), // 추석
    DateTime(2026, 10, 3),
    DateTime(2026, 10, 9),
    DateTime(2026, 12, 25),
  ];

  static bool isHoliday(DateTime date) {
    final d = DateTime(date.year, date.month, date.day);
    final list = date.year == 2025 ? _holidays2025 : (date.year == 2026 ? _holidays2026 : <DateTime>[]);
    return list.any((h) => h.year == d.year && h.month == d.month && h.day == d.day);
  }
}
