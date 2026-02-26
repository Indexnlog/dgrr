# 트러블슈팅 가이드

## 앱이 시뮬레이터에서 안 열릴 때

### 1. 기본 조치 (대부분 해결)
```bash
./scripts/run_ios.sh clean
```
- 기존 Flutter/Xcode 프로세스 종료 후 클린 빌드
- 시뮬레이터가 꺼져 있으면 자동 부팅
- **절대** `flutter run`을 여러 터미널에서 동시에 실행하지 말 것

### 2. 에러 로그 확인 (원인 파악용)
```bash
./scripts/run_ios.sh clean verbose
```
- `verbose` 옵션으로 상세 로그 출력 → 빌드 실패/앱 크래시 원인 확인

### 3. 그래도 안 되면
1. Cursor/IDE에서 실행 중인 `flutter run` 터미널이 있으면 `q`로 종료
2. **시뮬레이터를 먼저 수동 실행**: Spotlight에서 "Simulator" 검색 후 실행
3. 시뮬레이터: **Device → Erase All Content and Settings**
4. `./scripts/run_ios.sh clean` 재실행

### 4. Xcode "concurrent builds" 에러
- **원인**: 여러 `flutter run` 또는 `xcodebuild`가 동시에 실행됨
- **해결**: `run_ios.sh`가 자동으로 기존 프로세스를 종료함. 반드시 `./scripts/run_ios.sh` 사용

---

## UI 변경이 반영 안 될 때

- 터미널에서 **Shift+R** (Hot Restart)
- 또는 `q`로 종료 후 `./scripts/run_ios.sh` 재실행

---

## 화면이 깨져 보일 때 (overflow)

- Row/Column 내 Text에 `overflow: TextOverflow.ellipsis` 적용
- 긴 텍스트는 `Flexible`/`Expanded`로 감싸기
- `.cursor/rules/ui-overflow.mdc` 규칙 참고

---

## Firebase 에뮬레이터 사용 시

- 기본: 실제 Firebase 사용 (에뮬레이터 연결 안 함)
- 에뮬레이터 사용: `flutter run --dart-define=USE_FIREBASE_EMULATOR=true`
