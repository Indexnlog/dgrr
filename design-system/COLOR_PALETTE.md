# 앱 컬러 팔레트

> 레퍼런스 이미지에서 추출한 색상입니다.  
> Flutter 사용: `import 'package:dgrr_app/core/theme/app_palette.dart';`

---

## 1. 기본 팔레트 (18_palette_hex.png)

| 이름 | HEX | RGB | Flutter |
|------|-----|-----|---------|
| **Blue** | `#2f31f5` | 47, 49, 245 | `Color(0xFF2f31f5)` |
| **Lime / Yellow-Green** | `#dbf059` | 218, 240, 89 | `Color(0xFFdbf059)` |
| **Gray** | `#797979` | 121, 121, 121 | `Color(0xFF797979)` |
| **Platinum** | `#ebebe9` | 235, 235, 233 | `Color(0xFFebebe9)` |
| **Chinese Black** | `#131314` | 19, 19, 20 | `Color(0xFF131314)` |
| **White** | `#ffffff` | 255, 255, 255 | `Color(0xFFFFFFFF)` |

---

## 2. 오퍼시티 팔레트 (19_palette_opacity.png)

| 이름 | HEX | 용도 |
|------|-----|------|
| **Inch Worm** | `#A1E220` | 라임 그린 (50% opacity 변형 있음) |
| **Science Blue** | `#0A50D3` | 메인 블루 (60% opacity 변형 있음) |
| **Black** | `#000000` | 순수 검정 (70% opacity 변형 있음) |
| **Spring Sun** | `#F6FFE4` | 밝은 배경/크림 (80% opacity 변형 있음) |
| **Manz** | `#DBEE7E` | 연한 라임 (90% opacity 변형 있음) |

---

## 3. 브랜드 컬러 (20_brand_colors_typography.png)

| 이름 | HEX | 용도 |
|------|-----|------|
| **Black** | `#131313` | 텍스트, 헤더 |
| **Neon Green** | `#D2FF52` | 악센트, CTA, 활성 상태 |
| **Off-white** | `#F7F7F7` | 배경, 카드 |
| **Vibrant Blue** | `#1C46F5` | 프라이머리, 링크, 선택 |

**타이포그래피:** GROPLED, HELVETICA (레퍼런스) → 앱에서는 **Noto Sans KR** 적용

---

## 통합 권장 매핑 (영원FC)

| 역할 | 추천 색상 | HEX |
|------|-----------|-----|
| Primary | Vibrant Blue | `#1C46F5` |
| Accent / CTA | Neon Green | `#D2FF52` |
| Accent (보조) | Lime | `#dbf059` 또는 `#A1E220` |
| Background | Off-white / Platinum | `#F7F7F7` / `#ebebe9` |
| Surface / Card | White | `#ffffff` |
| Text Primary | Chinese Black | `#131314` |
| Text Secondary | Gray | `#797979` |
| Divider / Border | Platinum | `#ebebe9` |

---

## Flutter 상수

`lib/core/theme/app_palette.dart` 참고.
