"""
Signal Vault (sv_intelligence_bot) 텔레그램 메시지 발송 스크립트.
실행: python send_sv_message.py
"""
import asyncio
from telegram import Bot

# 발급받은 마스터키 (Token)
TOKEN = "8616695654:AAFWnuieanvWX-Ug_hBxI-Q3jzOLOxfivC8"

# 당신의 고유 주소 (Chat ID)
CHAT_ID = "6475054244"


async def main():
    bot = Bot(token=TOKEN)
    async with bot:
        # 전송할 메시지 내용
        message = (
            "🚨 [SV Intelligence] 시스템 가동. "
            "동료여, 첫 번째 데이터 파이프라인 연결에 성공했습니다."
        )
        await bot.send_message(chat_id=CHAT_ID, text=message)
    print("✅ 텔레그램 전송 완료! 핸드폰을 확인하세요.")


if __name__ == "__main__":
    asyncio.run(main())
