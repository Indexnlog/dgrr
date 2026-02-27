# 영원FC 어드민 웹

팀 관리·가입 승인용 웹 어드민입니다.

## 실행 방법

```bash
# 웹으로 실행
flutter run -d chrome

# 브라우저에서 http://localhost:포트번호/admin 접속
```

## 기능

- **팀 목록**: 등록된 팀 조회
- **팀 생성**: `teams` + `teams_public` 문서 생성
- **멤버 관리**: 팀별 멤버 목록, 가입 신청(pending) 승인/거절

## Firebase 웹 설정

웹에서 실행 시 Firebase 옵션이 필요합니다. `lib/firebase_options.dart`에 web 설정이 있어야 합니다.

웹 앱이 없다면 Firebase Console에서 웹 앱을 추가한 뒤:

```bash
dart run flutterfire_cli:flutterfire configure
```

실행 후 web 플랫폼을 선택하세요.
