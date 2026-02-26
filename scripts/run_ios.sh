#!/bin/bash
# iOS 시뮬레이터 실행 스크립트 (동시 빌드/앱 미실행 문제 방지)
# 사용: ./scripts/run_ios.sh [clean] [verbose]
#   clean: flutter clean 후 실행
#   verbose: 상세 로그 출력 (에러 확인용)
#
# ⚠️ 절대 flutter run을 여러 터미널에서 동시에 실행하지 말 것!
set -e

cd "$(dirname "$0")/.."

echo "🛑 기존 Flutter/Xcode 빌드 프로세스 종료..."
pkill -f "flutter run" 2>/dev/null || true
pkill -f "dart.*main.dart" 2>/dev/null || true
pkill -f "xcodebuild" 2>/dev/null || true
pkill -f "Runner.app" 2>/dev/null || true
sleep 3

# 시뮬레이터가 없으면 먼저 실행
if ! xcrun simctl list devices booted | grep -q "Booted"; then
  echo "📲 시뮬레이터 부팅 중..."
  open -a Simulator
  sleep 8
fi

NO_PUB="--no-pub"
VERBOSE=""
for arg in "$@"; do
  if [[ "$arg" == "clean" ]]; then
    echo "🧹 flutter clean 실행..."
    flutter clean && flutter pub get
    NO_PUB=""
  elif [[ "$arg" == "verbose" ]]; then
    VERBOSE="--verbose"
  fi
done

echo "📱 앱 빌드 및 실행..."
# -d ios는 디바이스 매칭 실패할 수 있음 → 첫 번째 iOS 시뮬레이터 UUID 사용
IOS_DEVICE=$(flutter devices 2>/dev/null | grep -E "simulator|ios" | grep -v "Chrome" | head -1 | grep -oE '[0-9A-F]{8}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{12}' || true)
if [[ -n "$IOS_DEVICE" ]]; then
  exec flutter run -d "$IOS_DEVICE" $NO_PUB $VERBOSE
else
  exec flutter run $NO_PUB $VERBOSE
fi
