# 디자인 레퍼런스

> 영원FC 앱 개발 시 UI/UX 참고용으로 수집한 레퍼런스 모음입니다.
> `design-system/영원fc/MASTER.md`와 함께 활용하세요.

---

## 목차

| # | 파일명 | 참고 포인트 |
|---|--------|-------------|
| 01 | `01_agon_fitness.png` | 챌린지 카드, 달력 스케줄, 네온 그린 악센트 |
| 02 | `02_car_rental.png` | 프로필 통계 카드, 캘린더 날짜 선택, 그린/터코이즈 그라데이션 |
| 03 | `03_brocker_chat.png` | 채팅 UI, 문서 첨부 플로우, 클레임 요약 카드 |
| 04 | `04_insurance_dark.png` | 다크 모드, 네온 그린 악센트, 세그먼트 필터 |
| 05 | `05_premier_league.png` | **매치 일정 리스트**, 팀 로고, 날짜/시간 표시 |
| 06 | `06_financial_claim.png` | 금액 시각화 바, 문서 카드, 클레임 상세 |
| 07 | `07_focusflow.png` | **달력 & 태스크**, 생산성 통계, 날짜별 색상 구분 |
| 08 | `08_finsync.png` | 대시보드 카드, 탭 네비게이션, 잔액/거래 표시 |
| 09 | `09_workout_calendar.png` | **달력 + 일정**, 운동 선택 카드, 날짜별 이벤트 |
| 10 | `10_www_template.png` | 요일 선택 바(MON~SUN), 블록 레이아웃 |
| 11 | `11_codewise.png` | 네비게이션 바, 블루/라임 그린 팔레트 |
| 12 | `12_budgeting_expenses.png` | 지출 카드 스택, 주간 그래프, 카테고리 아이콘 |
| 13 | `13_schedule_program.png` | **달력 + 프로그램**, 참여/미참여 시각 구분 |
| 14 | `14_supermarket_schedule.png` | **주간 스케줄 그리드**, 역할별 색상, 모달 확인 |
| 15 | `15_brand_colors.png` | 브랜드 컬러 가이드 (GROPLED, HELVETICA) |
| 16 | `16_color_palette.png` | HEX/RGB 팔레트 (#2f31f5, #dbf059, #131314 등) |
| 17 | `17_placeholder.png` | (추가 레퍼런스) |
| 18 | `18_palette_hex.png` | **기본 6색** Blue, Lime, Gray, Platinum, Black, White |
| 19 | `19_palette_opacity.png` | **오퍼시티 팔레트** Inch Worm, Science Blue, Spring Sun 등 |
| 20 | `20_brand_colors_typography.png` | **브랜드 4색** + GROPLED, HELVETICA 타이포 |

---

## 영원FC 적용 포인트

### 달력 & 일정
- **05_premier_league**: 매치 블록 레이아웃, 날짜/시간, 팀 로고 배치
- **07_focusflow**: 달력 색상 범례(중요/이벤트/미완료/팀)
- **09_workout_calendar**: 날짜별 이벤트 표시, 선택된 날짜 강조
- **13_schedule_program**: 참여/비참여 시각 구분(초록 스크리블 vs 미표시)
- **14_supermarket_schedule**: 주간 그리드, 역할별 색상 블록, 확인 모달

### 카드 & 리스트
- **01_agon_fitness**: 챌린지 카드, CTA 버튼 스타일
- **02_car_rental**: 통계 카드(총 km, 총 이용 횟수)
- **12_budgeting_expenses**: 스택형 카드, 카테고리별 색상

### 타이포그래피
- **20_brand_colors_typography**: GROPLED, HELVETICA (레퍼런스)
- **앱 적용**: Noto Sans KR (한국어 가독성, 모던 산세리프) → `lib/core/theme/app_typography.dart`

### 색상 팔레트
- **15_brand_colors**: #131313, #D2FF52, #F7F7F7, #1C46F5
- **16_color_palette**: #2f31f5(블루), #dbf059(라임), #131314(블랙), #ebebe9(플래티넘)
- **18_palette_hex**: 기본 6색 (→ `design-system/COLOR_PALETTE.md`, `app_palette.dart`)
- **19_palette_opacity**: Inch Worm #A1E220, Science Blue #0A50D3, Spring Sun #F6FFE4
- **20_brand_colors_typography**: 브랜드 4색 + 타이포그래피

### 참여 구분 (달력)
- 참여: 초록/라임 그린 마커
- 비참여: 회색 마커
- 미투표: 파랑/금색 마커

---

## 사용 방법

1. 새 화면/컴포넌트 설계 시 위 표에서 관련 레퍼런스 확인
2. `MASTER.md`의 컬러·타이포·스페이싱 규칙 준수
3. 레퍼런스는 **영감용** — 영원FC 브랜드(빨강/금색)에 맞게 조정
