# 영원FC 어드민 웹

팀 관리·가입 승인용 웹 어드민입니다.

## 실행 전 체크리스트

1. **어드민 이메일 등록**: `lib/admin/admin_config.dart`의 `adminAllowedEmails`에 본인 구글 이메일 추가
2. **웹 구글 로그인**: `web/index.html`의 `google-signin-client_id` meta 태그에 Web Client ID 설정 (상세: `docs/웹_구글_로그인_설정.md`)

## 실행 방법

```bash
# 웹으로 실행
flutter run -d chrome

# 브라우저에서 접속 (해시 기반)
# http://localhost:포트번호/#/admin
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
