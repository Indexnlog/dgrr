# 확장성 체크리스트 (Expansion Checklist)

현재 구조를 기반으로 앱 확장성을 위해 고려해야 할 사항들을 정리했습니다.

---

## 🔴 필수 (즉시 구현 권장)

### 1. 인증 상태 관리
**현재 상태:** 로그인만 구현됨, 로그인 후 상태 관리 없음

**필요한 것:**
- ✅ 사용자 인증 상태 Stream (`authStateChanges`)
- ✅ 현재 사용자 정보 Provider
- ✅ 로그아웃 기능
- ✅ 자동 로그인 유지 (토큰 갱신)

**구현 위치:**
```
lib/features/auth/presentation/providers/
  - auth_state_provider.dart (StreamProvider<User?>)
  - current_user_provider.dart (Provider<User?>)
```

**이유:** 모든 화면에서 인증 상태 확인 필요

---

### 2. 현재 팀 컨텍스트 관리
**현재 상태:** 팀 선택 후 상태 저장 안 됨

**필요한 것:**
- ✅ 현재 선택된 팀 Provider (`currentTeamIdProvider`)
- ✅ 사용자가 속한 팀 목록 Provider
- ✅ 팀 전환 기능 (여러 팀에 속할 수 있는 경우)
- ✅ 로컬 저장소에 현재 팀 ID 저장 (SharedPreferences)

**구현 위치:**
```
lib/features/teams/presentation/providers/
  - current_team_provider.dart
  - user_teams_provider.dart
```

**이유:** 모든 쿼리에서 `teamId` 필요, 전역적으로 관리해야 함

---

### 3. 라우팅 가드 (Auth Guards)
**현재 상태:** 라우팅 가드 없음

**필요한 것:**
- ✅ 인증되지 않은 사용자 → 로그인 화면
- ✅ 팀 선택 안 된 사용자 → 팀 선택 화면
- ✅ 권한 없는 사용자 → 접근 거부 화면

**구현 위치:**
```
lib/app/router/app_router.dart
  - redirect 로직 추가
```

**이유:** 보안 및 UX 필수

---

### 4. 권한 관리 (Role-Based Access Control)
**현재 상태:** 권한 체크 로직 없음

**필요한 것:**
- ✅ 현재 사용자의 팀 내 역할 확인 (`admin`, `treasurer`, `coach`, `member`)
- ✅ 역할별 접근 권한 Provider
- ✅ 권한 체크 헬퍼 함수

**구현 위치:**
```
lib/features/teams/domain/usecases/
  - get_current_user_role.dart
lib/features/teams/presentation/providers/
  - user_role_provider.dart
lib/core/permissions/
  - permission_checker.dart
```

**이유:** PRD에서 역할별 기능 구분 명확함 (Treasurer, Coach 등)

---

## 🟡 중요 (중기 구현 권장)

### 5. 오프라인 지원
**현재 상태:** 오프라인 캐싱 설정 안 됨

**필요한 것:**
- ✅ Firestore 오프라인 캐싱 활성화
- ✅ 오프라인 상태 감지
- ✅ 오프라인 큐 관리 (작업 저장 후 동기화)

**구현 위치:**
```
lib/main.dart
  - FirebaseFirestore.instance.settings = Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );
```

**이유:** 모바일 앱에서 네트워크 불안정 대비 필수

---

### 6. 에러 처리 전략
**현재 상태:** 각 화면에서 개별 처리

**필요한 것:**
- ✅ 통일된 에러 클래스 (`AppException`, `NetworkException` 등)
- ✅ 에러 핸들링 미들웨어
- ✅ 사용자 친화적 에러 메시지 매핑

**구현 위치:**
```
lib/core/errors/
  - exceptions.dart
  - error_handler.dart
```

**이유:** 일관된 에러 처리 및 디버깅 용이

---

### 7. 로딩 상태 관리
**현재 상태:** 각 화면에서 개별 관리

**필요한 것:**
- ✅ 전역 로딩 상태 Provider (선택사항)
- ✅ 로딩 오버레이 위젯

**구현 위치:**
```
lib/core/widgets/
  - loading_overlay.dart
```

**이유:** UX 일관성

---

### 8. 이미지 업로드 (Storage)
**현재 상태:** Storage 연동 없음

**필요한 것:**
- ✅ Firebase Storage 연동
- ✅ 이미지 업로드 UseCase
- ✅ 이미지 URL 관리

**구현 위치:**
```
lib/features/storage/
  - domain/usecases/upload_image.dart
  - data/datasources/storage_remote_data_source.dart
```

**이유:** 프로필 사진, 경기 영상 등 이미지 업로드 필요

---

## 🟢 선택 (장기 구현)

### 9. 푸시 알림 (FCM)
**현재 상태:** FCM 설정 안 됨

**필요한 것:**
- ✅ Firebase Cloud Messaging 설정
- ✅ 알림 권한 요청
- ✅ 알림 핸들링 로직
- ✅ 알림 토큰 관리

**구현 위치:**
```
lib/features/notifications/
  - presentation/providers/fcm_provider.dart
```

**이유:** PRD에서 "Nudge", "Alarm" 등 푸시 알림 명시됨

---

### 10. 페이지네이션
**현재 상태:** 모든 데이터 한 번에 로드

**필요한 것:**
- ✅ Firestore 쿼리 limit/startAfter 활용
- ✅ 무한 스크롤 구현
- ✅ 페이지네이션 Provider

**구현 위치:**
```
lib/core/pagination/
  - paginated_query_provider.dart
```

**이유:** 데이터가 많아질 때 성능 이슈 방지

---

### 11. 검색 기능
**현재 상태:** 검색 기능 없음

**필요한 것:**
- ✅ 팀 검색 (이미 `teams_public` 있음)
- ✅ 멤버 검색
- ✅ 경기 검색

**구현 위치:**
```
lib/features/search/
```

**이유:** 사용자 편의성

---

### 12. 실시간 업데이트 최적화
**현재 상태:** Stream 사용하지만 최적화 안 됨

**필요한 것:**
- ✅ 필요한 Stream만 구독 (메모리 최적화)
- ✅ Stream 구독 해제 관리
- ✅ Debounce/Throttle 적용 (필요시)

**구현 위치:**
```
lib/core/streams/
  - stream_manager.dart
```

**이유:** 성능 및 배터리 최적화

---

## 📋 우선순위별 구현 계획

### Phase 1: 핵심 인프라 (1-2주)
1. ✅ 인증 상태 관리
2. ✅ 현재 팀 컨텍스트 관리
3. ✅ 라우팅 가드
4. ✅ 권한 관리

### Phase 2: 사용자 경험 (2-3주)
5. ✅ 오프라인 지원
6. ✅ 에러 처리 전략
7. ✅ 로딩 상태 관리
8. ✅ 이미지 업로드

### Phase 3: 고급 기능 (3-4주)
9. ✅ 푸시 알림
10. ✅ 페이지네이션
11. ✅ 검색 기능
12. ✅ 실시간 업데이트 최적화

---

## 🎯 즉시 시작할 수 있는 것

### 1. 인증 상태 관리 (가장 중요)
```dart
// lib/features/auth/presentation/providers/auth_state_provider.dart
final authStateProvider = StreamProvider<User?>((ref) {
  return FirebaseAuth.instance.authStateChanges();
});

final currentUserProvider = Provider<User?>((ref) {
  return ref.watch(authStateProvider).value;
});
```

### 2. 현재 팀 컨텍스트
```dart
// lib/features/teams/presentation/providers/current_team_provider.dart
final currentTeamIdProvider = StateNotifierProvider<CurrentTeamNotifier, String?>((ref) {
  return CurrentTeamNotifier();
});
```

### 3. 라우팅 가드
```dart
// lib/app/router/app_router.dart
final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);
  final currentTeamId = ref.watch(currentTeamIdProvider);
  
  return GoRouter(
    redirect: (context, state) {
      final isAuthenticated = authState.value != null;
      final hasTeam = currentTeamId != null;
      
      if (!isAuthenticated && state.matchedLocation != '/login') {
        return '/login';
      }
      if (isAuthenticated && !hasTeam && state.matchedLocation != '/team-select') {
        return '/team-select';
      }
      return null;
    },
    routes: [...],
  );
});
```

---

## 💡 추가 고려사항

### 데이터 동기화 전략
- **Optimistic UI:** PRD에서 명시됨 (투표/출석)
- **Conflict Resolution:** 동시 수정 시 처리 전략

### 성능 최적화
- **이미지 캐싱:** `cached_network_image` 패키지 사용
- **리스트 최적화:** `ListView.builder` 사용 (이미 사용 중)
- **메모이제이션:** `freezed` 패키지 고려

### 테스트 전략
- **Unit Tests:** UseCase, Repository 테스트
- **Widget Tests:** 주요 화면 테스트
- **Integration Tests:** E2E 플로우 테스트

### 모니터링
- **Firebase Analytics:** 사용자 행동 추적
- **Crashlytics:** 에러 추적
- **Performance Monitoring:** 성능 모니터링

---

## 📌 다음에 할 일 (Backlog)

> 전체 남은 작업 통합. 우선순위별 구현 계획

---

### 1. PRD 기준 미구현/미완성

| PRD 항목 | 현재 상태 | 비고 |
|----------|-----------|------|
| **20일: 다음 달 등록 공지 초안** | 미구현 | "Draft & Approve" – 시스템이 초안 생성 |
| **Nudge (미납자 알림)** | UI만 있음 | `fee_management_page`에 버튼 있음, FCM 연동 없음 |
| **Court Alarm (Mon/Thu 23:30)** | 미구현 | FCM + 예약 알림 스케줄 |
| **Lateness: 지각 시간 선택** | 미구현 | "15분", "30분" 등 선택 UI 없음 |
| **Absence: 불참 사유** | 스키마만 | `absenceReasons` 있음, UI는 일부만 |
| **Tasks: 공 가져오기** | ✅ 완료 | "저도 들고가요" 자원 방식 |
| **MVP 투표** | 보류 | 당분간 미진행 |
| **경비 정산** | 미구현 | 경기 후 비용 분배 |

---

### 2. EXPANSION_CHECKLIST 기준

| 항목 | 상태 | 비고 |
|------|------|------|
| Phase 1 (인증·팀·라우팅·권한) | ✅ 완료 | |
| Phase 2 (오프라인·에러·로딩·이미지) | ✅ 완료 | |
| **FCM 푸시 알림** | ✅ 클라이언트 완료 | 토큰 저장, 권한 요청. Nudge는 Cloud Function 필요 |
| **페이지네이션** | 미구현 | 경기/투표 목록 등 |
| **검색** | 일부 | 팀 검색만, 멤버·경기 검색 없음 |
| **실시간 최적화** | 미구현 | Stream 구독 관리 등 |

---

### 3. UX 개선 (Backlog)

| 항목 | 현재 | 목표 | 우선순위 |
|------|------|------|----------|
| **Optimistic UI** | 서버 응답 후 갱신 | 탭 즉시 반영 | ✅ 완료 |
| **옵션별 로딩** | 전체 비활성화 | 해당 옵션만 로딩 | ✅ 완료 |
| **스켈레톤 UI** | CircularProgressIndicator | 카드 스켈레톤 | 낮음 |

---

### 4. 기타

| 항목 | 상태 |
|------|------|
| **수업 일정 자동화** | 나중에 (당분간 수동 유지) |
| **테스트** | Unit/Widget/Integration 미비 |
| **모니터링** | Analytics, Crashlytics, Performance 미설정 |
| **Conflict Resolution** | 동시 수정 시 처리 전략 없음 |

---

### 5. 성능·품질 (기능 많아도 버벅임 없이)

→ `docs/성능_품질_가이드.md` 참고

| 항목 | 설명 |
|------|------|
| Riverpod select/autoDispose | 불필요한 rebuild·리스너 제거 |
| Firestore limit·페이지네이션 | 초기 로딩·메모리 절약 |
| 탭 lazy 로딩 | 4탭 동시 메모리 부담 감소 |
| 이미지 캐시·리사이즈 | 네트워크·메모리 효율 |

---

### 6. 우선순위별 구현 제안

| 순서 | 항목 | 이유 |
|------|------|------|
| 1 | **Optimistic UI** | 규칙 명시, 작업량 적음 |
| 2 | **FCM 푸시 알림** | Nudge·Court Alarm 기반 |
| 3 | **지각 시간 선택** | PRD 필수, UI 추가 수준 |
| 4 | **공 가져오기 체크리스트** | PRD 필수, 경기 전 UX |
| 5 | **20일 등록 공지 초안** | Draft & Approve 핵심 |
| 6 | **미납자 Nudge 연동** | FCM 후, 총무 업무 자동화 |
| 7 | **페이지네이션** | 데이터 증가 시 성능 대비 |
| 8 | **나머지** | 경비 정산, 검색, 테스트 등 (MVP 보류) |

---

### 7. 추후 할 일 (추가 제안)

| 우선순위 | 항목 | 설명 |
|----------|------|------|
| 중 | **투표 마감 알림** | 등록/참석 투표 마감 D-1 푸시 |
| 중 | **캘린더 동기화** | 일정을 기기 캘린더에 추가 |
| 중 | **회비 내역 내보내기** | 엑셀/CSV로 납부 현황 다운로드 |
| 낮음 | **햅틱 피드백** | 투표/참석 탭 시 짧은 진동 |
| 낮음 | **에러 바운더리** | 크래시 시 복구 화면 |

→ 풀다운 새로고침, 회원 탈퇴, 오프라인 표시, 관리자 대시보드 등은 §10 참고

---

### 8. 개인 스포츠 데이터 고도화

| 영역 | 현재 | 목표 |
|------|------|------|
| **수업** | 없음 | N회 참석/전체, 출석률 |
| **경기** | 참석/불참만 | 참석률, 시즌별 |
| **경기 활약** | 없음 | 골 N개, 도움 N개 |
| **팀 합류** | 없음 | N일째 / N개월째 |

→ `docs/개인_스포츠_데이터_고도화_설계.md` 참고

---

### 9. 개인 풋살 즐거움 확대 (듀오링고 스타일)

#### 9.1 개인 기록·성과
| 항목 | 설명 |
|------|------|
| **시즌/월별 기록** | 골, 도움, 출석률 변화 추적 |
| **개인 최고 기록** | 한 경기 최다 골, 연속 출석 등 |
| **간단한 그래프** | 출석률·득점 추이 시각화 |

#### 9.2 성취감·게이미피케이션
| 항목 | 설명 |
|------|------|
| **뱃지/업적** | "10경기 연속 출석", "첫 골", "한 경기 2골" 등 |
| **레벨/등급** | 출석·활약에 따른 등급 (MVP, 핵심 멤버 등) |
| **연속 출석 스트릭** | "N일 연속 출석" 표시 |

#### 9.3 경기 하이라이트
| 항목 | 설명 |
|------|------|
| **내 골 경기 목록** | 내가 골 넣은 경기 목록, 간단한 요약 |

#### 9.4 편의·경험
| 항목 | 설명 |
|------|------|
| **경기장 위치·교통** | 지도, 대중교통/주차 정보 |
| **날씨** | 실내/실외에 따른 간단한 날씨 안내 |
| **준비물 체크** | 유니폼, 풋살화 등 개인 체크리스트 |

#### 9.5 재미 요소
| 항목 | 설명 |
|------|------|
| **나의 포지션** | 자주 뛴 포지션 요약 |
| **팀 내 역할** | "득점왕", "출석왕" 같은 별칭 |
| **시즌 요약 카드** | "2025년 나의 풋살 요약" 한 장 이미지 |

---

### 10. 완성도 확대

#### 10.1 사용자 경험(UX)
| 항목 | 설명 |
|------|------|
| **온보딩/튜토리얼** | 첫 가입자용 기능 안내, 팀 합류 후 주요 화면 설명 |
| **빈 상태(Empty State)** | 데이터 없을 때 안내 문구 + 다음 행동 유도 |
| **풀다운 새로고침** | 목록 화면에서 당겨서 새로고침 |
| **검색** | 팀원, 경기, 게시글 검색 |

#### 10.2 안정성·신뢰
| 항목 | 설명 |
|------|------|
| **오프라인 표시** | 네트워크 끊김 시 배너/토스트 |
| **재시도 버튼** | 로딩 실패 시 재시도 |
| **버전 체크** | 강제 업데이트 안내 (선택) |
| **에러 로깅** | Crashlytics 등으로 크래시·에러 수집 |

#### 10.3 관리자·운영
| 항목 | 설명 |
|------|------|
| **관리자 대시보드** | 팀 현황, 출석률, 회비 요약 등 |
| **팀 설정** | 팀명, 로고, 기본 규칙 등 |
| **회원 탈퇴 플로우** | 탈퇴 시 데이터 처리, 확인 절차 |

#### 10.4 법적·정책
| 항목 | 설명 |
|------|------|
| **개인정보처리방침** | 앱스토어 필수, 웹 링크 |
| **이용약관** | 서비스 이용 조건 |
| **알림 설정** | 푸시 on/off, 카테고리별 설정 |

#### 10.5 성장·확장
| 항목 | 설명 |
|------|------|
| **앱 내 피드백** | 버그/기능 제안 제출 |
| **공유 기능** | 경기·팀 정보 링크 공유 |
| **딥링크** | 특정 경기/게시글 직접 열기 |

---

**작성일:** 2025-01-18  
**최종 업데이트:** 2026-02-26  
**우선순위:** 필수 → 중요 → 선택 순서로 구현 권장
