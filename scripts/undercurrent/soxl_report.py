"""
Undercurrent — SOXL/SOX 전체 분석 리포트
역사적 저점 대비 현재 위치, RSI, MDD를 분석해 텔레그램으로 전송

실행: python scripts/undercurrent/soxl_report.py
필요: .env에 TELEGRAM_BOT_TOKEN, TELEGRAM_CHAT_ID
"""
import asyncio
import os
from datetime import datetime, timedelta

import yfinance as yf
from dotenv import load_dotenv

load_dotenv()

# 텔레그램 (Signal Vault)
TOKEN = os.environ.get("TELEGRAM_BOT_TOKEN")
CHAT_ID = os.environ.get("TELEGRAM_CHAT_ID")

# 역사적 저점 (수동 갱신 또는 자동 탐지)
SOXL_LOW_2022 = 8.20  # 2022.10 저점 근사치
SOX_LOW_2022 = 2030   # 2022.10 저점 근사치


def fetch_data(ticker: str, period: str = "2y") -> tuple:
    """yfinance로 데이터 수집. (df, 현재가) 반환."""
    t = yf.Ticker(ticker)
    df = t.history(period=period)
    if df.empty:
        return None, None
    current = df["Close"].iloc[-1]
    return df, current


def calc_rsi(series, period: int = 14) -> float | None:
    """RSI(14) 계산."""
    delta = series.diff()
    gain = delta.where(delta > 0, 0.0)
    loss = (-delta).where(delta < 0, 0.0)
    avg_gain = gain.rolling(window=period).mean()
    avg_loss = loss.rolling(window=period).mean()
    rs = avg_gain / avg_loss.replace(0, 1e-10)
    rsi = 100 - (100 / (1 + rs))
    val = rsi.iloc[-1] if not rsi.empty else None
    return float(val) if val is not None and val == val else None  # NaN check


def calc_mdd(series, window: int = 60) -> float | None:
    """최근 window일 MDD (최대 낙폭 %)."""
    if len(series) < window:
        window = len(series)
    recent = series.tail(window)
    rolling_max = recent.cummax()
    drawdown = (recent - rolling_max) / rolling_max * 100
    return float(drawdown.min()) if not drawdown.empty else None


def find_recent_low(series, lookback_days: int = 500) -> float | None:
    """최근 lookback_days 내 최저가."""
    recent = series.tail(lookback_days)
    return float(recent.min()) if not recent.empty else None


def build_report() -> str:
    """분석 리포트 문자열 생성."""
    df_soxl, price_soxl = fetch_data("SOXL", "2y")
    df_sox, price_sox = fetch_data("^SOX", "2y")

    if df_soxl is None or df_sox is None:
        return "⚠️ 데이터 수집 실패. yfinance 확인 필요."

    close_soxl = df_soxl["Close"]
    close_sox = df_sox["Close"]

    rsi_soxl = calc_rsi(close_soxl)
    mdd_soxl = calc_mdd(close_soxl, 60)
    low_soxl = find_recent_low(close_soxl)
    low_sox = find_recent_low(close_sox)

    # 저점 대비 % (2022 저점 또는 탐지된 저점 사용)
    low_ref_soxl = low_soxl or SOXL_LOW_2022
    low_ref_sox = low_sox or SOX_LOW_2022
    pct_above_low_soxl = ((price_soxl - low_ref_soxl) / low_ref_soxl * 100) if low_ref_soxl else None
    pct_above_low_sox = ((price_sox - low_ref_sox) / low_ref_sox * 100) if low_ref_sox else None

    # 사이클 구간 (저점~고점 중 몇 %)
    high_soxl = close_soxl.tail(500).max()
    cycle_pct = ((price_soxl - low_ref_soxl) / (high_soxl - low_ref_soxl) * 100) if high_soxl > low_ref_soxl else None

    # 요약 문장
    if rsi_soxl is not None:
        if rsi_soxl < 30:
            summary = "RSI 과매도. 추가 하락 가능성 있으나 반등 구간 진입 가능."
        elif rsi_soxl > 70:
            summary = "RSI 과매수. 조정 가능성."
        else:
            summary = "RSI 중립. 저점 대비 여유 있으면 급락 가능성 낮음."
    else:
        summary = "RSI 계산 불가."

    lines = [
        "📊 [Undercurrent] SOXL 사이클 리포트 " + datetime.now().strftime("%Y-%m-%d"),
        "",
        "📍 현재 vs 저점",
        f"• SOXL: ${price_soxl:.1f} (저점 ${low_ref_soxl:.1f} 대비 +{pct_above_low_soxl:.0f}%)" if pct_above_low_soxl else f"• SOXL: ${price_soxl:.1f}",
        f"• SOX: {price_sox:.0f} (저점 {low_ref_sox:.0f} 대비 +{pct_above_low_sox:.0f}%)" if pct_above_low_sox else f"• SOX: {price_sox:.0f}",
        "",
        "📉 기술적",
        f"• RSI(14): {rsi_soxl:.0f}" if rsi_soxl else "• RSI: N/A",
        f"• MDD(60일): {mdd_soxl:.1f}%" if mdd_soxl else "• MDD: N/A",
        "",
        "🔄 사이클",
        f"• 저점~고점 구간: 약 {cycle_pct:.0f}%" if cycle_pct is not None else "",
        "",
        f"💡 {summary}",
    ]
    return "\n".join(l for l in lines if l.strip())


async def send_telegram(text: str):
    """Signal Vault 봇으로 전송."""
    from telegram import Bot
    if not TOKEN or not CHAT_ID:
        print("⚠️ TELEGRAM_BOT_TOKEN, TELEGRAM_CHAT_ID를 .env에 설정하세요.")
        return
    bot = Bot(token=TOKEN)
    async with bot:
        await bot.send_message(chat_id=int(CHAT_ID), text=text)
    print("✅ 텔레그램 전송 완료!")


def main():
    report = build_report()
    print(report)
    print("\n---")
    asyncio.run(send_telegram(report))


if __name__ == "__main__":
    main()
