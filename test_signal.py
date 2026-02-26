"""
Signal Vault 봇 연결 테스트.
표준 라이브러리만 사용 — python-telegram-bot 불필요.
실행: python test_signal.py (프로젝트 루트에서)
"""
import json
import urllib.request
import urllib.error

TOKEN = "8616695654:AAFWnuieanvWX-Ug_hBxI-Q3jzOLOxfivC8"
CHAT_ID = "6475054244"
BASE = f"https://api.telegram.org/bot{TOKEN}"


def main():
    # 1) getMe — 봇 연결 테스트
    try:
        with urllib.request.urlopen(f"{BASE}/getMe") as resp:
            data = json.load(resp)
        if not data.get("ok"):
            print("❌ 봇 응답 오류:", data)
            return
        me = data["result"]
        print(f"✅ 봇 연결 성공: @{me['username']} ({me['first_name']})")
    except urllib.error.URLError as e:
        print("❌ 연결 실패:", e)
        return

    # 2) sendMessage — 테스트 메시지 발송
    body = json.dumps({"chat_id": CHAT_ID, "text": "🔬 [SV Intelligence] test_signal.py 실행 — 연결 테스트 성공."})
    req = urllib.request.Request(
        f"{BASE}/sendMessage",
        data=body.encode("utf-8"),
        headers={"Content-Type": "application/json"},
        method="POST",
    )
    try:
        with urllib.request.urlopen(req) as resp:
            data = json.load(resp)
        if data.get("ok"):
            print("✅ 테스트 메시지 전송 완료. 핸드폰을 확인하세요.")
        else:
            print("❌ 메시지 전송 실패:", data)
    except urllib.error.HTTPError as e:
        print("❌ 전송 실패:", e.code, e.read().decode())
    except urllib.error.URLError as e:
        print("❌ 전송 실패:", e)


if __name__ == "__main__":
    main()
