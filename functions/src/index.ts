import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

admin.initializeApp();

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
