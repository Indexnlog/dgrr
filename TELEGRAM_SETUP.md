# Telegram Bot 연동 (Signal Vault)

## 봇 정보

- **이름:** Signal Vault
- **사용자명:** `@sv_intelligence_bot`
- **링크:** https://t.me/sv_intelligence_bot

## 토큰 보안

⚠️ **Bot 토큰은 절대 앱 번들(APK/IPA)이나 Git 저장소에 포함하지 마세요.**

- **로컬 개발:** `.env.example`을 복사해 `.env`를 만들고, BotFather에서 받은 토큰을 `TELEGRAM_BOT_TOKEN`에 넣으세요.
- **운영 환경:** Firebase Cloud Functions 등 서버 환경의 환경 변수에만 저장하고, 앱에서는 토큰을 사용하지 마세요.  
  (알림 발송은 “앱 → Cloud Function → Telegram API” 흐름으로 구현하는 것을 권장합니다.)

## 설정 방법

1. 프로젝트 루트에 `.env` 파일 생성:
   ```bash
   cp .env.example .env
   ```
2. `.env`에 토큰 입력:
   ```
   TELEGRAM_BOT_TOKEN=발급받은_토큰
   ```
3. `.env`는 이미 `.gitignore`에 포함되어 있으므로 커밋되지 않습니다.

## 사용 예 (서버/Cloud Functions)

`lib/core/telegram/telegram_bot_client.dart`의 `TelegramBotClient.sendMessage()`를 사용할 수 있습니다.  
토큰은 환경 변수 등 서버 전용 경로에서만 읽어오세요.

- [Telegram Bot API](https://core.telegram.org/bots/api)
