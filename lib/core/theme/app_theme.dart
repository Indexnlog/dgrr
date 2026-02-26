// 레퍼런스 기반 디자인 시스템: Electric blue, Lime green, 카드 컬러
import 'package:flutter/material.dart';

class AppTheme {
  AppTheme._();

  // 배경
  static const bgDeep = Color(0xFF0D1117);
  static const bgCard = Color(0xFF161B22);
  static const bgCardLight = Color(0xFF1C2333);
  static const surface = Color(0xFF21262D);

  // 악센트 (레퍼런스: Electric blue + Lime green)
  static const primaryBlue = Color(0xFF2853E5);
  static const accentLime = Color(0xFFADFF00);
  static const accentGreen = Color(0xFF2EA043);
  static const attendGreen = Color(0xFF2EA043); // alias
  static const teamRed = Color(0xFFDC2626);
  static const accentOrange = Color(0xFFF97316);

  // 매치 카드 컬러 (Premier League 스타일)
  static const cardPink = Color(0xFFF472B6);
  static const cardBlue = Color(0xFF60A5FA);
  static const cardGreen = Color(0xFF4ADE80);
  static const cardOrange = Color(0xFFFB923C);

  // 텍스트
  static const textPrimary = Color(0xFFF0F6FC);
  static const textSecondary = Color(0xFF8B949E);
  static const textMuted = Color(0xFF484F58);

  // 기타
  static const gold = Color(0xFFFBBF24);
  static const absentRed = Color(0xFFDA3633);
  static const divider = Color(0xFF30363D);
  static const fixedBlue = Color(0xFF58A6FF);
  static const classBlue = Color(0xFF388BFD);

  /// 인덱스별 카드 배경색 (매치 카드용)
  static Color cardColorByIndex(int index) {
    final colors = [cardPink, cardBlue, cardGreen, cardOrange];
    return colors[index % colors.length];
  }
}
