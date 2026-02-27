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

