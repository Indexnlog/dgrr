# 새벽 3시 자동 푸시 설정

## 1. 스크립트 실행 권한

```bash
chmod +x scripts/auto_push.sh
```

## 2. launchd 등록 (macOS)

```bash
# plist 복사 (경로가 다르면 scripts/com.dgrr.autopush.plist 내 경로 수정)
cp scripts/com.dgrr.autopush.plist ~/Library/LaunchAgents/

# 로드
launchctl load ~/Library/LaunchAgents/com.dgrr.autopush.plist
```

## 3. 확인

```bash
launchctl list | grep com.dgrr.autopush
```

## 4. 수동 실행 테스트

```bash
./scripts/auto_push.sh
```

## 5. 해제

```bash
launchctl unload ~/Library/LaunchAgents/com.dgrr.autopush.plist
```

---

## 6. 텔레그램 알림 (푸시 성공 시만)

프로젝트 루트 `.env`에 다음이 있으면 푸시 성공 시 텔레그램으로 알림:

```
TELEGRAM_BOT_TOKEN=발급받은_토큰
TELEGRAM_CHAT_ID=채팅_ID
```

---

**주의**: Mac이 새벽 3시에 **켜져 있어야** 실행됩니다. 절전 모드/슬립 시 동작하지 않을 수 있습니다.
