import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'constants.dart';

class Helpers {
  // 📅 날짜 포맷팅
  static String formatDate(DateTime date) {
    return DateFormat('yyyy년 M월 d일', AppConstants.defaultLocale).format(date);
  }
  
  static String formatTime(DateTime time) {
    return DateFormat('HH:mm', AppConstants.defaultLocale).format(time);
  }
  
  static String formatDateTime(DateTime dateTime) {
    return DateFormat('yyyy년 M월 d일 HH:mm', AppConstants.defaultLocale).format(dateTime);
  }
  
  static String formatShortDate(DateTime date) {
    return DateFormat('M/d', AppConstants.defaultLocale).format(date);
  }
  
  static String formatWeekday(DateTime date) {
    final weekdays = ['월', '화', '수', '목', '금', '토', '일'];
    return weekdays[date.weekday - 1];
  }
  
  static String formatDateWithWeekday(DateTime date) {
    return '${formatDate(date)} (${formatWeekday(date)})';
  }
  
  static String formatRelativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inDays > 0) {
      return '${difference.inDays}일 전';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}시간 전';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}분 전';
    } else {
      return '방금 전';
    }
  }
  
  // ⚽ 축구 관련 날짜 유틸리티
  static DateTime getNextThursday(DateTime from) {
    final daysUntilThursday = (AppConstants.thursdayWeekday - from.weekday) % 7;
    return from.add(Duration(days: daysUntilThursday == 0 ? 7 : daysUntilThursday));
  }
  
  static DateTime getNextSunday(DateTime from) {
    final daysUntilSunday = (AppConstants.sundayWeekday - from.weekday) % 7;
    return from.add(Duration(days: daysUntilSunday == 0 ? 7 : daysUntilSunday));
  }
  
  static bool isReservationDay(DateTime date) {
    return date.weekday == AppConstants.thursdayWeekday || 
           date.weekday == AppConstants.mondayWeekday;
  }
  
  // 💰 금액 포맷팅
  static String formatCurrency(int amount) {
    final formatter = NumberFormat('#,###원', AppConstants.defaultLocale);
    return formatter.format(amount);
  }
  
  static String formatCurrencySimple(int amount) {
    if (amount >= 10000) {
      final man = amount ~/ 10000;
      final remainder = amount % 10000;
      if (remainder == 0) {
        return '${man}만원';
      } else {
        final remainderText = NumberFormat('#,###', AppConstants.defaultLocale).format(remainder);
        return '${man}만 ${remainderText}원';
      }
    }
    return formatCurrency(amount);
  }
  
  static String formatCurrencyCompact(int amount) {
    if (amount >= 100000000) {
      return '${(amount / 100000000).toStringAsFixed(1)}억원';
    } else if (amount >= 10000) {
      return '${(amount / 10000).toStringAsFixed(1)}만원';
    } else {
      return formatCurrency(amount);
    }
  }
  
  // 📊 통계 관련
  static double calculateAttendanceRate(int attendedCount, int totalCount) {
    if (totalCount == 0) return 0.0;
    return (attendedCount / totalCount) * 100;
  }
  
  static String formatPercentage(double percentage) {
    return '${percentage.toStringAsFixed(1)}%';
  }
  
  static String formatGoalRecord(int goals, int assists) {
    if (goals == 0 && assists == 0) return '-';
    if (assists == 0) return '${goals}골';
    if (goals == 0) return '${assists}도움';
    return '${goals}골 ${assists}도움';
  }
  
  // 📱 스낵바 표시
  static void showSnackBar(
    BuildContext context,
    String message, {
    Color? backgroundColor,
    Duration duration = const Duration(seconds: 3),
    SnackBarAction? action,
  }) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
        duration: duration,
        action: action,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(AppConstants.defaultPadding),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        ),
      ),
    );
  }
  
  static void showSuccessSnackBar(BuildContext context, String message) {
    showSnackBar(
      context,
      message,
      backgroundColor: Colors.green.shade600,
    );
  }
  
  static void showErrorSnackBar(BuildContext context, String message) {
    showSnackBar(
      context,
      message,
      backgroundColor: Colors.red.shade600,
    );
  }
  
  static void showWarningSnackBar(BuildContext context, String message) {
    showSnackBar(
      context,
      message,
      backgroundColor: Colors.orange.shade600,
    );
  }
  
  static void showInfoSnackBar(BuildContext context, String message) {
    showSnackBar(
      context,
      message,
      backgroundColor: Colors.blue.shade600,
    );
  }
  
  // 🔧 다이얼로그
  static Future<bool> showConfirmDialog(
    BuildContext context,
    String title,
    String content, {
    String confirmText = '확인',
    String cancelText = '취소',
    Color? confirmColor,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(cancelText),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: confirmColor != null 
                ? ElevatedButton.styleFrom(backgroundColor: confirmColor)
                : null,
            child: Text(confirmText),
          ),
        ],
      ),
    );
    return result ?? false;
  }
  
  static Future<bool> showDeleteConfirmDialog(
    BuildContext context,
    String itemName,
  ) async {
    return showConfirmDialog(
      context,
      '삭제 확인',
      '정말로 "$itemName"을(를) 삭제하시겠습니까?\n삭제된 데이터는 복구할 수 없습니다.',
      confirmText: '삭제',
      cancelText: '취소',
      confirmColor: Colors.red,
    );
  }
  
  static void showInfoDialog(
    BuildContext context,
    String title,
    String content, {
    String buttonText = '확인',
  }) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(buttonText),
          ),
        ],
      ),
    );
  }
  
  // 🔍 로딩 다이얼로그
  static void showLoadingDialog(
    BuildContext context, {
    String message = '처리 중...',
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(width: AppConstants.defaultPadding),
            Expanded(child: Text(message)),
          ],
        ),
      ),
    );
  }
  
  static void hideLoadingDialog(BuildContext context) {
    Navigator.of(context, rootNavigator: true).pop();
  }
  
  // 📏 화면 크기 유틸
  static bool isTablet(BuildContext context) {
    return MediaQuery.of(context).size.width >= 768;
  }
  
  static bool isSmallScreen(BuildContext context) {
    return MediaQuery.of(context).size.width < 360;
  }
  
  static bool isLargeScreen(BuildContext context) {
    return MediaQuery.of(context).size.width >= 1200;
  }
  
  static double getScreenWidth(BuildContext context) {
    return MediaQuery.of(context).size.width;
  }
  
  static double getScreenHeight(BuildContext context) {
    return MediaQuery.of(context).size.height;
  }
  
  static EdgeInsets getResponsivePadding(BuildContext context) {
    if (isTablet(context)) {
      return const EdgeInsets.all(AppConstants.extraLargePadding);
    } else {
      return const EdgeInsets.all(AppConstants.defaultPadding);
    }
  }
  
  // 🎨 색상 유틸
  static Color darken(Color color, [double amount = 0.1]) {
    assert(amount >= 0 && amount <= 1);
    final hsl = HSLColor.fromColor(color);
    final hslDark = hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0));
    return hslDark.toColor();
  }
  
  static Color lighten(Color color, [double amount = 0.1]) {
    assert(amount >= 0 && amount <= 1);
    final hsl = HSLColor.fromColor(color);
    final hslLight = hsl.withLightness((hsl.lightness + amount).clamp(0.0, 1.0));
    return hslLight.toColor();
  }
  
  static Color getContrastColor(Color backgroundColor) {
    final luminance = backgroundColor.computeLuminance();
    return luminance > 0.5 ? Colors.black : Colors.white;
  }
  
  // 📱 진동 피드백
  static void lightVibration() {
    HapticFeedback.lightImpact();
  }
  
  static void mediumVibration() {
    HapticFeedback.mediumImpact();
  }
  
  static void heavyVibration() {
    HapticFeedback.heavyImpact();
  }
  
  static void selectionVibration() {
    HapticFeedback.selectionClick();
  }
  
  // 🔗 유효성 검사
  static bool isValidUrl(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.hasScheme && (uri.scheme == 'http' || uri.scheme == 'https');
    } catch (e) {
      return false;
    }
  }
  
  static bool isValidEmail(String email) {
    return RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(email);
  }
  
  static bool isValidPhoneNumber(String phoneNumber) {
    // 한국 휴대폰 번호 패턴
    return RegExp(r'^01[016789]-?\d{3,4}-?\d{4}$').hasMatch(phoneNumber);
  }
  
  static bool isValidPassword(String password) {
    return password.length >= AppConstants.minPasswordLength;
  }
  
  static bool isValidName(String name) {
    return name.isNotEmpty && 
           name.length <= AppConstants.maxNameLength &&
           name.trim().isNotEmpty;
  }
  
  // 📱 네비게이션 헬퍼
  static void pushPage(BuildContext context, Widget page) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => page),
    );
  }
  
  static void pushReplacePage(BuildContext context, Widget page) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => page),
    );
  }
  
  static void popToRoot(BuildContext context) {
    Navigator.of(context).popUntil((route) => route.isFirst);
  }
  
  // 🎯 역할 관련 유틸
  static bool hasAdminAccess(String role) {
    return [
      AppConstants.roleOwner,
      AppConstants.roleAdmin,
      AppConstants.roleManager,
    ].contains(role);
  }
  
  static bool hasFinancialAccess(String role) {
    return [
      AppConstants.roleOwner,
      AppConstants.roleAdmin,
      AppConstants.roleTreasurer,
    ].contains(role);
  }
  
  static String getRoleDisplayName(String role) {
    switch (role) {
      case AppConstants.roleOwner:
        return '팀장';
      case AppConstants.roleAdmin:
        return '관리자';
      case AppConstants.roleManager:
        return '매니저';
      case AppConstants.roleTreasurer:
        return '총무';
      case AppConstants.roleMember:
        return '일반 회원';
      default:
        return '회원';
    }
  }
  
  // 📊 출석 관련
  static String getAttendanceDisplayName(String status) {
    switch (status) {
      case AppConstants.attendanceStatusPresent:
        return '출석';
      case AppConstants.attendanceStatusAbsent:
        return '결석';
      case AppConstants.attendanceStatusLate:
        return '지각';
      case AppConstants.attendanceStatusExcused:
        return '사유결석';
      default:
        return '미확인';
    }
  }
  
  static Color getAttendanceColor(String status) {
    switch (status) {
      case AppConstants.attendanceStatusPresent:
        return Colors.green;
      case AppConstants.attendanceStatusAbsent:
        return Colors.red;
      case AppConstants.attendanceStatusLate:
        return Colors.orange;
      case AppConstants.attendanceStatusExcused:
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }
  
  // 🔧 문자열 유틸
  static String truncateText(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength)}...';
  }
  
  static String capitalizeFirst(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }
  
  // 📱 키보드 관련
  static void hideKeyboard(BuildContext context) {
    FocusScope.of(context).unfocus();
  }
  
  // 🎲 기타 유틸
  static String generateRandomId() {
    return DateTime.now().millisecondsSinceEpoch.toString();
  }
  
  static bool isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && 
           date.month == now.month && 
           date.day == now.day;
  }
  
  static bool isThisWeek(DateTime date) {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 6));
    
    return date.isAfter(startOfWeek.subtract(const Duration(days: 1))) &&
           date.isBefore(endOfWeek.add(const Duration(days: 1)));
  }
}