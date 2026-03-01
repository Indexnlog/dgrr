// 라이트 모드 디자인 시스템: Electric blue, Lime green
import 'package:flutter/material.dart';

class AppTheme {
  AppTheme._();

  // 배경 (라이트)
  static const bgDeep = Color(0xFFF5F7FA);
  static const bgCard = Color(0xFFFFFFFF);
  static const bgCardLight = Color(0xFFF8FAFC);
  static const surface = Color(0xFFEEF1F5);

  // 악센트 (Electric blue + Lime green)
  static const primaryBlue = Color(0xFF2853E5);
  static const accentLime = Color(0xFF9ACD32); // 네비 활성 표시 (파란 배경 위)
  static const accentGreen = Color(0xFF2EA043);
  static const attendGreen = Color(0xFF2EA043); // alias
  static const teamRed = Color(0xFFDC2626);
  static const accentOrange = Color(0xFFF97316);

  // 매치 카드 컬러
  static const cardPink = Color(0xFFF472B6);
  static const cardBlue = Color(0xFF60A5FA);
  static const cardGreen = Color(0xFF4ADE80);
  static const cardOrange = Color(0xFFFB923C);

  // 텍스트 (라이트 배경용)
  static const textPrimary = Color(0xFF1A1D21);
  static const textSecondary = Color(0xFF5C6370);
  static const textMuted = Color(0xFF8B949E);

  // 기타
  static const gold = Color(0xFFFBBF24);
  static const absentRed = Color(0xFFDA3633);
  static const divider = Color(0xFFE5E8EC);
  static const fixedBlue = Color(0xFF2853E5);
  static const classBlue = Color(0xFF388BFD);

  /// 인덱스별 카드 배경색 (매치 카드용)
  static Color cardColorByIndex(int index) {
    final colors = [cardPink, cardBlue, cardGreen, cardOrange];
    return colors[index % colors.length];
  }
}
