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

**작성일:** 2025-01-18  
**우선순위:** 필수 → 중요 → 선택 순서로 구현 권장
