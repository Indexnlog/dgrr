"""
Signal Vault 봇 연결 테스트.
실행: python test_signal.py (scripts/telegram 폴더에서)
"""
import asyncio
from telegram import Bot

TOKEN = "8616695654:AAFWnuieanvWX-Ug_hBxI-Q3jzOLOxfivC8"
CHAT_ID = "6475054244"


async def main():
    bot = Bot(token=TOKEN)
    async with bot:
        # 봇 정보 확인 (연결 테스트)
        me = await bot.get_me()
        print(f"✅ 봇 연결 성공: @{me.username} ({me.first_name})")
        # 테스트 메시지 발송
        await bot.send_message(
            chat_id=CHAT_ID,
            text="🔬 [SV Intelligence] test_signal.py 실행 — 연결 테스트 성공.",
        )
        print("✅ 테스트 메시지 전송 완료. 핸드폰을 확인하세요.")


if __name__ == "__main__":
    asyncio.run(main())
