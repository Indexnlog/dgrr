class AppConstants {
  // 🎨 앱 정보
  static const String appName = '지구공';
  static const String appVersion = '1.0.0+1';
  static const String appDescription = '축구팀 관리 플랫폼';
  
  // 🔥 Firestore 컬렉션명
  static const String teamsCollection = 'teams';
  static const String membersCollection = 'members';
  static const String eventsCollection = 'events';
  static const String noticesCollection = 'notices';
  static const String pollsCollection = 'polls';
  static const String transactionsCollection = 'transactions';
  static const String regularFeesCollection = 'regular_fees';
  static const String classFeesCollection = 'class_fees';
  static const String reservationsCollection = 'reservations';
  static const String matchesCollection = 'matches';
  static const String roundsCollection = 'rounds';
  static const String recordsCollection = 'records';
  static const String feedbacksCollection = 'feedbacks';
  static const String notificationsCollection = 'notifications';
  static const String matchMediaCollection = 'match_media';
  
  // 💾 SharedPreferences 키
  static const String selectedTeamIdKey = 'selectedTeamId';
  static const String userIdKey = 'userId';
  static const String userEmailKey = 'userEmail';
  static const String userNameKey = 'userName';
  static const String userRoleKey = 'userRole';
  static const String isFirstLaunchKey = 'isFirstLaunch';
  static const String themePreferenceKey = 'themePreference';
  static const String autoReservationKey = 'autoReservation';
  static const String notificationEnabledKey = 'notificationEnabled';
  
  // 👤 사용자 역할 (기존 구조 반영)
  static const String roleMember = 'member';
  static const String roleAdmin = 'admin';
  static const String roleManager = 'manager';
  static const String roleOwner = 'owner';
  static const String roleTreasurer = 'treasurer'; // 총무
  
  // 📅 일정 타입
  static const String eventTypeMatch = 'match';
  static const String eventTypeClass = 'class';
  static const String eventTypeMeeting = 'meeting';
  static const String eventTypeReservation = 'reservation';
  static const String eventTypeOther = 'other';
  
  // ⚽ 경기 상태
  static const String matchStatusScheduled = 'scheduled';
  static const String matchStatusInProgress = 'in_progress';
  static const String matchStatusCompleted = 'completed';
  static const String matchStatusCancelled = 'cancelled';
  
  // 💰 결제 상태
  static const String paymentStatusPending = 'pending';
  static const String paymentStatusCompleted = 'completed';
  static const String paymentStatusCancelled = 'cancelled';
  static const String paymentStatusRefunded = 'refunded';
  
  // 📊 투표 상태
  static const String pollStatusActive = 'active';
  static const String pollStatusClosed = 'closed';
  static const String pollStatusDraft = 'draft';
  
  // 🎯 출석 상태
  static const String attendanceStatusPresent = 'present';
  static const String attendanceStatusAbsent = 'absent';
  static const String attendanceStatusLate = 'late';
  static const String attendanceStatusExcused = 'excused';
  
  // 📱 UI 상수
  static const double defaultPadding = 16.0;
  static const double smallPadding = 8.0;
  static const double largePadding = 24.0;
  static const double extraLargePadding = 32.0;
  static const double borderRadius = 8.0;
  static const double cardBorderRadius = 12.0;
  static const double buttonHeight = 48.0;
  static const double inputFieldHeight = 56.0;
  
  // 🏟️ 구장 예약 자동화 설정
  static const int reservationHour = 23;
  static const int reservationMinute = 59;
  static const int reservationSecond = 30;
  
  // 📅 예약 요일 설정
  static const int thursdayWeekday = 4;  // 목요일
  static const int mondayWeekday = 1;    // 월요일
  static const int sundayWeekday = 7;    // 일요일
  
  // ⏰ 예약 시간대
  static const List<String> thursdayReservationTimes = ['20:00', '21:00'];
  static const List<String> sundayReservationTimes = ['18:00', '19:00'];
  
  // 📊 페이지네이션
  static const int defaultPageSize = 20;
  static const int maxPageSize = 50;
  static const int minPageSize = 10;
  
  // 🔔 알림 관련
  static const String notificationChannelId = 'zigugong_notifications'
  static const String notificationChannelName = '지구공 알림';
  static const String notificationChannelDescription = '일정, 공지사항, 투표 등의 알림';
  
  // 📸 이미지 업로드 제한
  static const int maxImageSizeMB = 10;
  static const int imageQuality = 80;
  static const int maxImageWidth = 1920;
  static const int maxImageHeight = 1920;
  static const List<String> supportedImageTypes = ['jpg', 'jpeg', 'png', 'webp'];
  
  // 🔗 외부 링크
  static const String supportEmail = 'support@zigugong.com';
  static const String privacyPolicyUrl = 'https://zigugong.com/privacy';
  static const String termsOfServiceUrl = 'https://zigugong.com/terms';
  static const String githubUrl = 'https://github.com/zigugong/app';
  
  // ⏰ 타임아웃 설정
  static const Duration networkTimeout = Duration(seconds: 30);
  static const Duration shortTimeout = Duration(seconds: 10);
  static const Duration longTimeout = Duration(minutes: 2);
  static const Duration cacheExpiration = Duration(hours: 1);
  
  // 🔄 재시도 설정
  static const int maxRetryAttempts = 3;
  static const Duration retryDelay = Duration(seconds: 2);
  
  // 📝 텍스트 길이 제한
  static const int maxNameLength = 50;
  static const int maxDescriptionLength = 500;
  static const int maxCommentLength = 200;
  static const int minPasswordLength = 6;
  
  // 🎮 게임 관련 상수 (매치 기록용)
  static const int maxGoalsPerMatch = 50;
  static const int maxPlayersPerTeam = 30;
  static const int standardMatchDurationMinutes = 90;
  
  // 🏆 통계 관련
  static const int recentMatchesCount = 10;
  static const int topScorersCount = 5;
  static const int monthsToShowInStats = 12;
  
  // 🌍 기본 로케일
  static const String defaultLocale = 'ko_KR';
  static const String fallbackLocale = 'en_US';
  
  // 🎯 기본값들
  static const String defaultProfileImageUrl = 'assets/default_profile.png';
  static const String defaultTeamColor = '#2E7D32';
  static const int defaultMembershipFee = 20000;
  static const int defaultClassFee = 10000;
}