"""
Signal Vault (sv_intelligence_bot) 텔레그램 메시지 발송 스크립트.
실행: .env 설정 후 python send_sv_message.py
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
        # 전송할 메시지 내용
        message = (
            "🚨 [SV Intelligence] 시스템 가동. "
            "동료여, 첫 번째 데이터 파이프라인 연결에 성공했습니다."
        )
        await bot.send_message(chat_id=int(CHAT_ID), text=message)
    print("✅ 텔레그램 전송 완료! 핸드폰을 확인하세요.")


if __name__ == "__main__":
    asyncio.run(main())
