---
tags:
  - dgrr
  - telegram
  - bot
  - setup
created: 2026-02-26
---

# 텔레그램 봇 연동 (Signal Vault)

## 봇 정보

| 항목 | 값 |
|------|-----|
| **이름** | Signal Vault |
| **사용자명** | `@sv_intelligence_bot` |
| **링크** | https://t.me/sv_intelligence_bot |

---

## 1. 토큰 발급

1. 텔레그램에서 `@BotFather` 검색
2. `/mybots` → 본인 봇 선택 → **API Token**
3. 표시된 토큰 복사 (예: `8616695654:AAFWnuieanvWX-Ug_hBxI-Q3jzOLOxfivC8`)

## 2. Chat ID 확인

- 봇에게 아무 메시지 보내기 (예: `/start`)
- 브라우저: `https://api.telegram.org/bot<토큰>/getUpdates`
- JSON 응답의 `message.chat.id` 값이 Chat ID

---

## 3. 프로젝트 설정

### 3.1 .env 파일 생성

프로젝트 루트(`dgrr_app/`)에 `.env` 생성:

```
TELEGRAM_BOT_TOKEN=발급받은_토큰
TELEGRAM_CHAT_ID=6475054244
```

### 3.2 Python 패키지 설치

```bash
cd /Users/yeomhajisoo/dgrr_app
pip install -r scripts/telegram/requirements.txt
```

**필요 패키지:** `python-telegram-bot`, `python-dotenv`, `anyio>=4.0.0`

> ⚠️ `anyio` 2.x 사용 시 `AttributeError: CancelScope` 발생 → `pip install --upgrade anyio` 실행

### 3.3 Cursor 터미널에서 .env 사용

`.vscode/settings.json`에 `"python.terminal.useEnvFile": true` 설정됨 (프로젝트에 포함)

---

## 4. 실행

```bash
cd /Users/yeomhajisoo/dgrr_app
python scripts/telegram/send_sv_message.py
```

성공 시: `✅ 텔레그램 전송 완료! 핸드폰을 확인하세요.`

---

## 5. 보안

- **토큰은 절대 Git에 커밋하지 마세요.** `.env`는 `.gitignore`에 포함됨
- 토큰 노출 시: BotFather에서 **Revoke current token** 후 새 토큰 발급
- `.env.example`에 템플릿만 두고, 실제 값은 `.env`에만 저장

---

## 6. 관련 파일

| 경로 | 설명 |
|------|------|
| `scripts/telegram/send_sv_message.py` | 메시지 발송 스크립트 |
| `scripts/telegram/test_signal.py` | 연결 테스트 스크립트 |
| `scripts/telegram/requirements.txt` | Python 의존성 |
| `.env.example` | 환경 변수 템플릿 |
