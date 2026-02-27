#!/bin/bash
# 새벽 3시 자동 푸시 스크립트
# 변경 사항이 있으면 커밋 후 푸시

set -e
REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO_DIR"

# 변경 사항 확인 (추적 중인 파일만)
if git diff --quiet && git diff --cached --quiet; then
  echo "[$(date '+%Y-%m-%d %H:%M')] 변경 사항 없음"
  exit 0
fi

# 스테이징 (.vscode, cd 제외)
git add -A
git reset -- .vscode/ cd 2>/dev/null || true

if git diff --cached --quiet; then
  echo "[$(date '+%Y-%m-%d %H:%M')] 커밋할 변경 사항 없음"
  exit 0
fi

MSG="chore: auto-push $(date '+%Y-%m-%d %H:%M')"
git commit -m "$MSG"
git push origin main
echo "[$(date '+%Y-%m-%d %H:%M')] 푸시 완료: $MSG"

# 푸시 성공 시 텔레그램 알림
if [ -f "$REPO_DIR/.env" ]; then
  source "$REPO_DIR/.env"
fi
if [ -n "$TELEGRAM_BOT_TOKEN" ] && [ -n "$TELEGRAM_CHAT_ID" ]; then
  TEXT="📤 dgrr auto-push 완료 - $(date '+%Y-%m-%d %H:%M')"
  curl -s -X POST "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage" \
    -d "chat_id=${TELEGRAM_CHAT_ID}" \
    -d "text=${TEXT}" > /dev/null 2>&1 || true
fi
