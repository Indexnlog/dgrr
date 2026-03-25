// 앱 타이포그래피 (레퍼런스 앱 퀄리티)
//
// - Noto Sans KR: 한국어 가독성, 모던 산세리프
// - letterSpacing, height로 시각적 계층 강화
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_theme.dart';

class AppTypography {
  AppTypography._();

  static TextTheme get textTheme {
    final base = GoogleFonts.notoSansKrTextTheme();
    return base.copyWith(
      // Display: 대형 헤드라인 (28~34)
      displayLarge: base.displayLarge?.copyWith(
        color: AppTheme.textPrimary,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.8,
        height: 1.2,
      ),
      displayMedium: base.displayMedium?.copyWith(
        color: AppTheme.textPrimary,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.6,
        height: 1.2,
      ),
      displaySmall: base.displaySmall?.copyWith(
        color: AppTheme.textPrimary,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
      ),

      // Headline: 섹션 제목 (20~24)
      headlineLarge: base.headlineLarge?.copyWith(
        color: AppTheme.textPrimary,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.5,
        height: 1.25,
      ),
      headlineMedium: base.headlineMedium?.copyWith(
        color: AppTheme.textPrimary,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.4,
      ),
      headlineSmall: base.headlineSmall?.copyWith(
        color: AppTheme.textPrimary,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.3,
      ),

      // Title: 카드/리스트 제목 (16~18)
      titleLarge: base.titleLarge?.copyWith(
        color: AppTheme.textPrimary,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.2,
      ),
      titleMedium: base.titleMedium?.copyWith(
        color: AppTheme.textPrimary,
        fontWeight: FontWeight.w600,
      ),
      titleSmall: base.titleSmall?.copyWith(
        color: AppTheme.textPrimary,
        fontWeight: FontWeight.w600,
      ),

      // Body: 본문
      bodyLarge: base.bodyLarge?.copyWith(
        color: AppTheme.textPrimary,
        fontWeight: FontWeight.w500,
        height: 1.4,
      ),
      bodyMedium: base.bodyMedium?.copyWith(
        color: AppTheme.textSecondary,
        fontWeight: FontWeight.w500,
        height: 1.4,
      ),
      bodySmall: base.bodySmall?.copyWith(
        color: AppTheme.textMuted,
        fontWeight: FontWeight.w500,
        height: 1.35,
      ),

      // Label: 버튼, 칩, 캡션
      labelLarge: base.labelLarge?.copyWith(
        color: AppTheme.textPrimary,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.2,
      ),
      labelMedium: base.labelMedium?.copyWith(
        color: AppTheme.textSecondary,
        fontWeight: FontWeight.w600,
      ),
      labelSmall: base.labelSmall?.copyWith(
        color: AppTheme.textMuted,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
      ),
    );
  }

  /// 상단바/네비 등 고정 영역용 (흰색 텍스트)
  static TextTheme get invertedTextTheme {
    final base = textTheme;
    return base.copyWith(
      displayLarge: base.displayLarge?.copyWith(color: Colors.white),
      displayMedium: base.displayMedium?.copyWith(color: Colors.white),
      displaySmall: base.displaySmall?.copyWith(color: Colors.white),
      headlineLarge: base.headlineLarge?.copyWith(color: Colors.white),
      headlineMedium: base.headlineMedium?.copyWith(color: Colors.white),
      headlineSmall: base.headlineSmall?.copyWith(color: Colors.white),
      titleLarge: base.titleLarge?.copyWith(color: Colors.white),
      titleMedium: base.titleMedium?.copyWith(color: Colors.white),
      titleSmall: base.titleSmall?.copyWith(color: Colors.white),
      bodyLarge: base.bodyLarge?.copyWith(color: Colors.white),
      bodyMedium: base.bodyMedium?.copyWith(color: Colors.white.withValues(alpha: 0.9)),
      bodySmall: base.bodySmall?.copyWith(color: Colors.white.withValues(alpha: 0.8)),
      labelLarge: base.labelLarge?.copyWith(color: Colors.white),
      labelMedium: base.labelMedium?.copyWith(color: Colors.white),
      labelSmall: base.labelSmall?.copyWith(color: Colors.white.withValues(alpha: 0.9)),
    );
  }
}
