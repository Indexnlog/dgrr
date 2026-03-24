# 영원FC (Young-won FC)

풋살 팀 관리 Flutter 앱. Firebase 기반.

---

## 스택

- **Flutter** + **Riverpod** + **GoRouter**
- **Firebase**: Auth, Firestore, Storage

---

## 실행

```bash
# iOS 시뮬레이터 (권장: 동시 빌드 충돌 방지)
./scripts/run_ios.sh

# 앱이 안 열리거나 빌드 꼬였을 때
./scripts/run_ios.sh clean

# 직접 실행
flutter run -d ios
```

> ⚠️ `flutter run`은 **한 터미널에서만** 실행. 여러 개 동시 실행 시 Xcode 빌드 실패.
> 문제 발생 시 [TROUBLESHOOTING.md](TROUBLESHOOTING.md) 참고.

---

## App Check (보안)

- 앱은 기본적으로 App Check 초기화를 시도합니다.
- 웹은 `FIREBASE_APP_CHECK_WEB_SITE_KEY`가 없으면 App Check를 건너뜁니다.
- 에뮬레이터 모드(`USE_FIREBASE_EMULATOR=true`)에서는 App Check를 생략합니다.

```bash
# 웹 빌드/배포 시 예시
--dart-define=FIREBASE_APP_CHECK_WEB_SITE_KEY=YOUR_RECAPTCHA_V3_SITE_KEY
```

---

## 문서

| 문서 | 설명 |
|------|------|
| [TROUBLESHOOTING.md](TROUBLESHOOTING.md) | 시뮬레이터/빌드 문제 해결 |
| [docs/README.md](docs/README.md) | 개발문서 인덱스 |
| [PRD.md](PRD.md) | 프로덕트 요구사항 |
| [SCHEMA.md](SCHEMA.md) | Firestore 스키마 |
| [docs/06_배포_가이드.md](docs/06_배포_가이드.md) | APK/스토어 배포 |

---

## 구조

- `lib/features/` — 기능별 모듈 (auth, matches, polls, schedule 등)
- `lib/app/` — 라우터, 공통 위젯
- `lib/core/` — 테마, 권한, 에러

