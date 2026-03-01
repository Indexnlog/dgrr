/// 앱 컬러 팔레트 (레퍼런스 이미지 기반)
///
/// 참고: design-system/COLOR_PALETTE.md
/// - 18_palette_hex: 기본 6색
/// - 19_palette_opacity: Inch Worm, Science Blue 등
/// - 20_brand_colors: 브랜드 4색
import 'package:flutter/material.dart';

class AppPalette {
  AppPalette._();

  // === 기본 팔레트 (18_palette_hex) ===
  static const blue = Color(0xFF2f31f5);
  static const lime = Color(0xFFdbf059);
  static const gray = Color(0xFF797979);
  static const platinum = Color(0xFFebebe9);
  static const chineseBlack = Color(0xFF131314);
  static const white = Color(0xFFFFFFFF);

  // === 오퍼시티 팔레트 (19_palette_opacity) ===
  static const inchWorm = Color(0xFFA1E220);   // 라임 그린
  static const scienceBlue = Color(0xFF0A50D3);  // 메인 블루
  static const black = Color(0xFF000000);
  static const springSun = Color(0xFFF6FFE4);   // 밝은 배경
  static const manz = Color(0xFFDBEE7E);        // 연한 라임

  // === 브랜드 컬러 (20_brand_colors) ===
  static const brandBlack = Color(0xFF131313);
  static const neonGreen = Color(0xFFD2FF52);
  static const offWhite = Color(0xFFF7F7F7);
  static const vibrantBlue = Color(0xFF1C46F5);

  // === 오퍼시티 변형 (필요 시 사용) ===
  static Color inchWorm50([double opacity = 0.5]) =>
      inchWorm.withOpacity(opacity);
  static Color scienceBlue60([double opacity = 0.6]) =>
      scienceBlue.withOpacity(opacity);
  static Color black70([double opacity = 0.7]) =>
      black.withOpacity(opacity);
  static Color springSun80([double opacity = 0.8]) =>
      springSun.withOpacity(opacity);
  static Color manz90([double opacity = 0.9]) =>
      manz.withOpacity(opacity);
}
