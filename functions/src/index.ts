import * as functions from "firebase-functions/v1";
import * as admin from "firebase-admin";

admin.initializeApp();

function getTelegramConfig() {
  const c = functions.config().telegram || {};
  return {
    botToken: (c.bot_token as string) || "",
    adminChatId: (c.admin_chat_id as string) || "",
  };
}

async function sendTelegram(
  text: string,
  replyMarkup?: { inline_keyboard: Array<Array<{ text: string; callback_data: string }>> }
): Promise<boolean> {
  const { botToken, adminChatId } = getTelegramConfig();
  if (!botToken || !adminChatId) return false;
  const body: Record<string, unknown> = {
    chat_id: adminChatId,
    text,
    parse_mode: "HTML",
  };
  if (replyMarkup) body.reply_markup = replyMarkup;
  const res = await fetch(`https://api.telegram.org/bot${botToken}/sendMessage`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify(body),
  });
  return res.ok;
}

/**
 * 가입 신청 시 Telegram 알림 (승인/거절 버튼 포함)
 * - teams/{teamId}/members/{userId} 생성/업데이트 시 status가 'pending'이면 발송
 */
export const onMemberJoinRequest = functions.firestore
  .document("teams/{teamId}/members/{userId}")
  .onWrite(async (change, context) => {
    const after = change.after.data();
    const before = change.before.data();
    if (!after || after.status !== "pending") return null;

    // 이전에 이미 pending이었으면 중복 발송 방지
    if (before && before.status === "pending") return null;

    const { teamId, userId } = context.params;
    const db = admin.firestore();

    // 팀명 조회
    const teamDoc = await db.collection("teams").doc(teamId).get();
    const teamName = (teamDoc.data()?.name as string) || teamId;

    // 사용자 이름 (Firebase Auth)
    let userName = userId;
    try {
      const userRecord = await admin.auth().getUser(userId);
      userName = userRecord.displayName || userRecord.email || userId;
    } catch {
      // ignore
    }

    const text = `🆕 <b>신규 가입 신청</b>\n\n` +
      `팀: ${teamName}\n` +
      `신청자: ${userName}\n` +
      `(ID: ${userId})\n\n` +
      `아래 버튼으로 승인/거절하세요.`;

    const callbackDataApprove = `approve:${teamId}:${userId}`;
    const callbackDataReject = `reject:${teamId}:${userId}`;
    if (callbackDataApprove.length > 64 || callbackDataReject.length > 64) {
      functions.logger.warn("callback_data too long, skipping");
      return null;
    }

    await sendTelegram(text, {
      inline_keyboard: [
        [{ text: "✅ 승인", callback_data: callbackDataApprove }],
        [{ text: "❌ 거절", callback_data: callbackDataReject }],
      ],
    });

    return null;
  });

/**
 * Telegram Webhook: 승인/거절 버튼 처리
 * - deploy 후: https://api.telegram.org/bot<TOKEN>/setWebhook?url=<FUNCTION_URL>
 */
export const telegramWebhook = functions.https.onRequest(async (req, res) => {
  if (req.method !== "POST") {
    res.status(405).send("Method Not Allowed");
    return;
  }

  const body = req.body as { callback_query?: { id: string; data?: string; from?: { id: number } } };
  const callback = body?.callback_query;
  if (!callback?.data) {
    res.status(200).send("ok");
    return;
  }

  const [action, teamId, userId] = callback.data.split(":");
  if (!action || !teamId || !userId || !["approve", "reject"].includes(action)) {
    res.status(200).send("ok");
    return;
  }

  const db = admin.firestore();
  const memberRef = db.collection("teams").doc(teamId).collection("members").doc(userId);
  const newStatus = action === "approve" ? "active" : "rejected";

  try {
    await memberRef.update({ status: newStatus });
  } catch (e) {
    functions.logger.error("member update failed", e);
    res.status(200).send("ok");
    return;
  }

  // Telegram에 "처리됨" 응답
  const { botToken } = getTelegramConfig();
  const answerText = action === "approve" ? "✅ 승인 완료" : "❌ 거절 완료";
  if (botToken) {
    await fetch(
      `https://api.telegram.org/bot${botToken}/answerCallbackQuery`,
    {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        callback_query_id: callback.id,
        text: answerText,
      }),
    }
    );
  }

  res.status(200).send("ok");
});

/**
 * 미납자 Nudge: 미납 회원들에게 FCM 푸시 발송
 * - Input: teamId, feeId (seasonId, yyyy-MM)
 * - Query: teams/{teamId}/registrations where eventId==feeId, status!='paid'
 * - FCM tokens from teams/{teamId}/members/{userId}.fcmToken
 */
export const sendNudgeToUnpaid = functions.https.onCall(
  async (request) => {
    if (!request.auth) {
      throw new functions.https.HttpsError(
        "unauthenticated",
        "로그인이 필요합니다."
      );
    }

    const { teamId, feeId } = request.data as { teamId?: string; feeId?: string };
    if (!teamId || !feeId) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "teamId와 feeId가 필요합니다."
      );
    }

    const db = admin.firestore();
    const regsRef = db
      .collection("teams")
      .doc(teamId)
      .collection("registrations");

    // 미납자 조회: eventId == feeId, status != 'paid'
    const unpaidSnapshot = await regsRef
      .where("eventId", "==", feeId)
      .where("status", "!=", "paid")
      .get();

    const unpaidUids = unpaidSnapshot.docs
      .map((d) => d.data().userId as string | undefined)
      .filter((uid): uid is string => Boolean(uid));

    if (unpaidUids.length === 0) {
      return { sent: 0, message: "미납자가 없습니다." };
    }

    // FCM 토큰 조회
    const tokens: string[] = [];
    const membersRef = db.collection("teams").doc(teamId).collection("members");

    for (const uid of unpaidUids) {
      const memberDoc = await membersRef.doc(uid).get();
      const token = memberDoc.data()?.fcmToken as string | undefined;
      if (token) {
        tokens.push(token);
      }
    }

    if (tokens.length === 0) {
      return { sent: 0, message: "발송 가능한 FCM 토큰이 없습니다." };
    }

    // FCM 발송
    const messaging = admin.messaging();
    const response = await messaging.sendEachForMulticast({
      tokens,
      notification: {
        title: "회비 납부 안내",
        body: "이번 달 회비 납부를 확인해 주세요.",
      },
      data: {
        type: "nudge",
        teamId,
        seasonId: feeId,
      },
    });

    return {
      sent: response.successCount,
      failed: response.failureCount,
      total: tokens.length,
    };
  }
);

/**
 * 20일 등록 공지 초안: 매월 20일 09:00 KST에 다음 달 월별 등록 투표 초안 생성
 * - Draft & Approve: isActive=false로 생성 → 총무/운영진이 확인 후 활성화
 */
export const draftRegistrationNoticeScheduled = functions.pubsub
  .schedule("0 9 20 * *")
  .timeZone("Asia/Seoul")
  .onRun(async () => {
    const db = admin.firestore();
    const now = new Date();
    const nextMonth = new Date(now.getFullYear(), now.getMonth() + 1, 1);
    const targetMonth = `${nextMonth.getFullYear()}-${String(nextMonth.getMonth() + 1).padStart(2, "0")}`;

    const teamsSnap = await db.collection("teams").get();

    for (const teamDoc of teamsSnap.docs) {
      const teamId = teamDoc.id;
      const pollsRef = db.collection("teams").doc(teamId).collection("polls");

      const existing = await pollsRef
        .where("category", "==", "membership")
        .where("targetMonth", "==", targetMonth)
        .limit(1)
        .get();

      if (!existing.empty) continue;

      const year = nextMonth.getFullYear();
      const monthLabel = nextMonth.getMonth() + 1;
      await pollsRef.add({
        title: `${year}년 ${monthLabel}월 등록 여부 투표`,
        description: "다음 달 등록/휴회/미등록(인정사유) 중 선택해 주세요. 기간: 매월 20일~24일",
        type: "option",
        category: "membership",
        targetMonth,
        anonymous: false,
        canChangeVote: true,
        maxSelections: 1,
        showResultBeforeDeadline: false,
        isActive: false,
        expiresAt: admin.firestore.Timestamp.fromDate(
          new Date(nextMonth.getFullYear(), nextMonth.getMonth(), 24, 23, 59, 59)
        ),
        createdBy: "system",
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        options: [
          { id: "registered", text: "등록 (월 5만원) · 수업/경기 참가", voteCount: 0, votes: [] },
          { id: "paused", text: "휴회 (월 2만원) · 개인 사유 불참", voteCount: 0, votes: [] },
          { id: "exempt", text: "미등록(인정사유) (0원) · 부상·출산 등", voteCount: 0, votes: [] },
        ],
      });
    }

    return null;
  });

/**
 * Court Alarm: 매주 월/목 23:30 KST에 예약 공지 알림
 * - reservation_notices에서 내일 예약이 있는 팀 조회
 * - 해당 팀 멤버들에게 FCM 발송
 */
export const courtAlarmScheduled = functions.pubsub
  .schedule("30 23 * * 1,4")
  .timeZone("Asia/Seoul")
  .onRun(async () => {
    const db = admin.firestore();
    const messaging = admin.messaging();

    const now = new Date();
    const tomorrow = new Date(now);
    tomorrow.setDate(tomorrow.getDate() + 1);
    const tomorrowStart = new Date(tomorrow.getFullYear(), tomorrow.getMonth(), tomorrow.getDate());
    const tomorrowEnd = new Date(tomorrowStart);
    tomorrowEnd.setDate(tomorrowEnd.getDate() + 1);

    const teamsSnap = await db.collection("teams").get();

    for (const teamDoc of teamsSnap.docs) {
      const teamId = teamDoc.id;
      const noticesRef = db
        .collection("teams")
        .doc(teamId)
        .collection("reservation_notices")
        .where("targetDate", ">=", tomorrowStart)
        .where("targetDate", "<", tomorrowEnd)
        .limit(1);

      const noticesSnap = await noticesRef.get();
      if (noticesSnap.empty) continue;

      const membersSnap = await db
        .collection("teams")
        .doc(teamId)
        .collection("members")
        .where("status", "==", "active")
        .get();

      const tokens: string[] = [];
      membersSnap.docs.forEach((d) => {
        const token = d.data()?.fcmToken as string | undefined;
        if (token) tokens.push(token);
      });

      if (tokens.length === 0) continue;

      await messaging.sendEachForMulticast({
        tokens,
        notification: {
          title: "내일 구장 예약 안내",
          body: "내일 예약이 있습니다. 예약 시도 시간을 확인해 주세요.",
        },
        data: { type: "court_alarm", teamId },
      });
    }

    return null;
  });
