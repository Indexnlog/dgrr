"""
Signal Vault 봇 연결 테스트.
실행: .env 설정 후 python test_signal.py (프로젝트 루트에서)
"""
import asyncio
import os

from dotenv import load_dotenv
from telegram import Bot

load_dotenv()

TOKEN = os.environ.get("TELEGRAM_BOT_TOKEN")
CHAT_ID = os.environ.get("TELEGRAM_CHAT_ID")


async def main():
    if not TOKEN or not CHAT_ID:
        raise SystemExit("TELEGRAM_BOT_TOKEN, TELEGRAM_CHAT_ID를 .env에 설정하세요.")
    bot = Bot(token=TOKEN)
    async with bot:
        # 봇 정보 확인 (연결 테스트)
        me = await bot.get_me()
        print(f"✅ 봇 연결 성공: @{me.username} ({me.first_name})")
        # 테스트 메시지 발송
        await bot.send_message(
            chat_id=int(CHAT_ID),
            text="🔬 [SV Intelligence] test_signal.py 실행 — 연결 테스트 성공.",
        )
        print("✅ 테스트 메시지 전송 완료. 핸드폰을 확인하세요.")


if __name__ == "__main__":
    asyncio.run(main())
