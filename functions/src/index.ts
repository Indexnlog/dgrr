import * as functions from "firebase-functions/v1";
import * as admin from "firebase-admin";

admin.initializeApp();

const PRIVILEGED_ROLES = ["admin", "운영진", "총무", "treasurer", "coach"];

async function getMemberRole(teamId: string, uid: string): Promise<string | null> {
  const snap = await admin
    .firestore()
    .collection("teams")
    .doc(teamId)
    .collection("members")
    .doc(uid)
    .get();
  if (!snap.exists) return null;
  const role = snap.data()?.role;
  return typeof role == "string" ? role : null;
}

async function assertPrivilegedMember(teamId: string, uid: string): Promise<void> {
  const role = await getMemberRole(teamId, uid);
  if (!role || !PRIVILEGED_ROLES.includes(role)) {
    throw new functions.https.HttpsError(
      "permission-denied",
      "권한이 없습니다."
    );
  }
}

function assertAppCheck(request: { app?: unknown }): void {
  // Emulator 환경에서는 App Check 검증을 건너뛴다.
  const isEmulator = process.env.FUNCTIONS_EMULATOR === "true";
  if (isEmulator) return;

  if (!request.app) {
    throw new functions.https.HttpsError(
      "failed-precondition",
      "App Check 검증이 필요합니다."
    );
  }
}

async function enforceRateLimit(params: {
  teamId: string;
  uid: string;
  action: string;
  limit: number;
  windowSeconds: number;
}): Promise<void> {
  const { teamId, uid, action, limit, windowSeconds } = params;
  const db = admin.firestore();
  const ref = db
    .collection("teams")
    .doc(teamId)
    .collection("rate_limits")
    .doc(`${uid}_${action}`);

  await db.runTransaction(async (tx) => {
    const snap = await tx.get(ref);
    const now = Date.now();
    const windowStart = now - windowSeconds * 1000;

    if (!snap.exists) {
      tx.set(ref, {
        uid,
        action,
        count: 1,
        firstAt: admin.firestore.Timestamp.fromMillis(now),
        lastAt: admin.firestore.Timestamp.fromMillis(now),
      });
      return;
    }

    const data = snap.data() || {};
    const firstAt = (data.firstAt as admin.firestore.Timestamp | undefined)?.toMillis() || now;
    const count = typeof data.count === "number" ? data.count : 0;

    if (firstAt >= windowStart) {
      if (count >= limit) {
        throw new functions.https.HttpsError(
          "resource-exhausted",
          "요청이 너무 많습니다. 잠시 후 다시 시도해 주세요."
        );
      }
      tx.update(ref, {
        count: count + 1,
        lastAt: admin.firestore.Timestamp.fromMillis(now),
      });
      return;
    }

    tx.update(ref, {
      count: 1,
      firstAt: admin.firestore.Timestamp.fromMillis(now),
      lastAt: admin.firestore.Timestamp.fromMillis(now),
    });
  });
}

async function runIdempotent<T>(params: {
  teamId: string;
  uid: string;
  action: string;
  requestId: string;
  handler: () => Promise<T>;
}): Promise<T> {
  const { teamId, uid, action, requestId, handler } = params;
  const db = admin.firestore();
  const key = `${uid}_${action}_${requestId}`;
  const ref = db.collection("teams").doc(teamId).collection("idempotency").doc(key);

  const existing = await ref.get();
  if (existing.exists) {
    const payload = existing.data()?.response as T | undefined;
    if (payload !== undefined) {
      return payload;
    }
  }

  const response = await handler();
  await ref.set(
    {
      uid,
      action,
      requestId,
      response,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    },
    { merge: true }
  );
  return response;
}

async function appendAuditLog(params: {
  teamId: string;
  actorUid: string;
  action: string;
  targetType: string;
  targetId: string;
  before?: Record<string, unknown>;
  after?: Record<string, unknown>;
  meta?: Record<string, unknown>;
}): Promise<void> {
  const { teamId, actorUid, action, targetType, targetId, before, after, meta } = params;
  try {
    await admin
      .firestore()
      .collection("teams")
      .doc(teamId)
      .collection("audit_logs")
      .add({
        actorUid,
        action,
        targetType,
        targetId,
        before: before || null,
        after: after || null,
        meta: meta || null,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });
  } catch (e) {
    functions.logger.error("appendAuditLog failed", e);
  }
}

async function recordFailureMetric(params: {
  teamId?: string;
  action: string;
  errorCode: string;
}): Promise<void> {
  const { teamId, action, errorCode } = params;
  if (!teamId) return;
  try {
    const now = new Date();
    const key = `${now.getFullYear()}-${String(now.getMonth() + 1).padStart(2, "0")}-${String(now.getDate()).padStart(2, "0")}`;
    const ref = admin
      .firestore()
      .collection("teams")
      .doc(teamId)
      .collection("ops_metrics_daily")
      .doc(key);
    await ref.set(
      {
        date: key,
        [`failures.${action}.total`]: admin.firestore.FieldValue.increment(1),
        [`failures.${action}.codes.${errorCode}`]: admin.firestore.FieldValue.increment(1),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      },
      { merge: true }
    );
  } catch (e) {
    functions.logger.error("recordFailureMetric failed", e);
  }
}

function toDateFromEventFields(data: FirebaseFirestore.DocumentData): Date | null {
  const dateRaw = data.date;
  const startTimeRaw = typeof data.startTime === "string" ? data.startTime : "20:00";
  if (dateRaw instanceof admin.firestore.Timestamp) {
    return dateRaw.toDate();
  }
  if (typeof dateRaw === "string") {
    const [hh, mm] = startTimeRaw.split(":");
    const composed = new Date(`${dateRaw}T${(hh || "20").padStart(2, "0")}:${(mm || "00").padStart(2, "0")}:00+09:00`);
    return Number.isNaN(composed.getTime()) ? null : composed;
  }
  return null;
}

async function fetchWeatherSnapshot(lat: number, lng: number): Promise<{
  weatherSummary: string;
  tempC: number | null;
  rainProb: number | null;
}> {
  const url =
    `https://api.open-meteo.com/v1/forecast?latitude=${lat}&longitude=${lng}` +
    "&current=temperature_2m,precipitation_probability,weather_code&timezone=Asia%2FSeoul";
  const res = await fetch(url);
  if (!res.ok) {
    throw new Error(`weather api error: ${res.status}`);
  }
  const json = (await res.json()) as {
    current?: {
      temperature_2m?: number;
      precipitation_probability?: number;
      weather_code?: number;
    };
  };
  const code = json.current?.weather_code;
  const weatherSummary = (() => {
    if (code === undefined) return "정보없음";
    if ([0].includes(code)) return "맑음";
    if ([1, 2].includes(code)) return "구름조금";
    if ([3].includes(code)) return "흐림";
    if ([45, 48].includes(code)) return "안개";
    if ([51, 53, 55, 61, 63, 65, 80, 81, 82].includes(code)) return "비";
    if ([71, 73, 75, 85, 86].includes(code)) return "눈";
    if ([95, 96, 99].includes(code)) return "뇌우";
    return "기타";
  })();
  return {
    weatherSummary,
    tempC: typeof json.current?.temperature_2m === "number" ? json.current.temperature_2m : null,
    rainProb:
      typeof json.current?.precipitation_probability === "number"
        ? json.current.precipitation_probability
        : null,
  };
}

async function updateWeatherForCollection(params: {
  teamId: string;
  collection: "matches" | "events";
  beforeHours: number;
  now: Date;
}): Promise<number> {
  const { teamId, collection, beforeHours, now } = params;
  const db = admin.firestore();
  const colRef = db.collection("teams").doc(teamId).collection(collection);
  const snap = await colRef.limit(300).get();
  let updated = 0;

  for (const doc of snap.docs) {
    const data = doc.data();
    const lat = typeof data.lat === "number" ? data.lat : null;
    const lng = typeof data.lng === "number" ? data.lng : null;
    if (lat === null || lng === null) continue;

    const eventAt = toDateFromEventFields(data);
    if (!eventAt) continue;
    const diffMs = eventAt.getTime() - now.getTime();
    if (diffMs < 0) continue;
    const diffHours = diffMs / (1000 * 60 * 60);
    if (Math.abs(diffHours - beforeHours) > 0.6) continue;

    try {
      const weather = await fetchWeatherSnapshot(lat, lng);
      await doc.ref.set(
        {
          weatherSummary: weather.weatherSummary,
          tempC: weather.tempC,
          rainProb: weather.rainProb,
          weatherUpdatedAt: admin.firestore.FieldValue.serverTimestamp(),
        },
        { merge: true }
      );
      updated += 1;
    } catch (e) {
      functions.logger.warn("weather snapshot update failed", {
        teamId,
        collection,
        docId: doc.id,
        error: String(e),
      });
    }
  }
  return updated;
}

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
 * - FCM tokens from teams/{teamId}/member_tokens/{userId}.fcmToken
 */
export const sendNudgeToUnpaid = functions.https.onCall(
  async (request) => {
    const { teamId, feeId, requestId } = request.data as {
      teamId?: string;
      feeId?: string;
      requestId?: string;
    };
    try {
      assertAppCheck(request);
      if (!request.auth) {
        throw new functions.https.HttpsError(
          "unauthenticated",
          "로그인이 필요합니다."
        );
      }
      if (!teamId || !feeId || !requestId) {
        throw new functions.https.HttpsError(
          "invalid-argument",
          "teamId, feeId, requestId가 필요합니다."
        );
      }
      await assertPrivilegedMember(teamId, request.auth.uid);
      await enforceRateLimit({
        teamId,
        uid: request.auth.uid,
        action: "sendNudgeToUnpaid",
        limit: 5,
        windowSeconds: 60,
      });

      return runIdempotent({
        teamId,
        uid: request.auth.uid,
        action: "sendNudgeToUnpaid",
        requestId,
        handler: async () => {
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
        const memberTokensRef = db.collection("teams").doc(teamId).collection("member_tokens");

        for (const uid of unpaidUids) {
          const tokenDoc = await memberTokensRef.doc(uid).get();
          let token = tokenDoc.data()?.fcmToken as string | undefined;
          // 마이그레이션 기간: 기존 members.fcmToken 폴백
          if (!token) {
            const memberDoc = await db
              .collection("teams")
              .doc(teamId)
              .collection("members")
              .doc(uid)
              .get();
            token = memberDoc.data()?.fcmToken as string | undefined;
          }
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

          const payload = {
          sent: response.successCount,
          failed: response.failureCount,
          total: tokens.length,
          };
          await appendAuditLog({
            teamId,
            actorUid: request.auth.uid,
            action: "nudge_send",
            targetType: "fee",
            targetId: feeId,
            after: payload as unknown as Record<string, unknown>,
          });
          return payload;
        }
      });
    } catch (error) {
      const code = error instanceof functions.https.HttpsError ? error.code : "internal";
      await recordFailureMetric({
        teamId,
        action: "sendNudgeToUnpaid",
        errorCode: code,
      });
      throw error;
    }
  }
);

/**
 * 회비 납부 상태 변경 (민감 액션 - 서버 전용)
 * - Input: teamId, registrationId, status('paid' | 'pending')
 */
export const updateRegistrationPaymentStatus = functions.https.onCall(
  async (request) => {
    const { teamId, registrationId, status } = request.data as {
      teamId?: string;
      registrationId?: string;
      status?: string;
      requestId?: string;
    };
    const requestId = (request.data as { requestId?: string }).requestId;
    try {
      assertAppCheck(request);
      if (!request.auth) {
        throw new functions.https.HttpsError(
          "unauthenticated",
          "로그인이 필요합니다."
        );
      }
      if (!teamId || !registrationId || !status || !requestId) {
        throw new functions.https.HttpsError(
          "invalid-argument",
          "teamId, registrationId, status, requestId가 필요합니다."
        );
      }
      if (!["paid", "pending"].includes(status)) {
        throw new functions.https.HttpsError(
          "invalid-argument",
          "status는 paid 또는 pending만 허용됩니다."
        );
      }

      await assertPrivilegedMember(teamId, request.auth.uid);
      await enforceRateLimit({
        teamId,
        uid: request.auth.uid,
        action: "updateRegistrationPaymentStatus",
        limit: 20,
        windowSeconds: 60,
      });

      return runIdempotent({
        teamId,
        uid: request.auth.uid,
        action: "updateRegistrationPaymentStatus",
        requestId,
        handler: async () => {
        const regRef = admin
          .firestore()
          .collection("teams")
          .doc(teamId)
          .collection("registrations")
          .doc(registrationId);

        const regSnap = await regRef.get();
        if (!regSnap.exists) {
          throw new functions.https.HttpsError(
            "not-found",
            "등록 정보를 찾을 수 없습니다."
          );
        }

        await regRef.update({
          status,
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
          paymentConfirmedBy: request.auth.uid,
          paymentConfirmedAt: admin.firestore.FieldValue.serverTimestamp(),
        });
        await appendAuditLog({
          teamId,
          actorUid: request.auth.uid,
          action: "registration_payment_status_update",
          targetType: "registration",
          targetId: registrationId,
          after: { status },
        });

        return { ok: true };
        },
      });
    } catch (error) {
      const code = error instanceof functions.https.HttpsError ? error.code : "internal";
      await recordFailureMetric({
        teamId,
        action: "updateRegistrationPaymentStatus",
        errorCode: code,
      });
      throw error;
    }
  }
);

/**
 * 예약 성공/실패 보고 (민감 액션 - 서버 전용)
 * - Input: teamId, noticeId, groundId, result('success'|'failed')
 */
export const reportReservationResult = functions.https.onCall(
  async (request) => {
    const { teamId, noticeId, groundId, result } = request.data as {
      teamId?: string;
      noticeId?: string;
      groundId?: string;
      result?: string;
      requestId?: string;
    };
    const requestId = (request.data as { requestId?: string }).requestId;
    try {
      assertAppCheck(request);
      if (!request.auth) {
        throw new functions.https.HttpsError(
          "unauthenticated",
          "로그인이 필요합니다."
        );
      }
      if (!teamId || !noticeId || !groundId || !result || !requestId) {
        throw new functions.https.HttpsError(
          "invalid-argument",
          "teamId, noticeId, groundId, result, requestId가 필요합니다."
        );
      }
      if (!["success", "failed"].includes(result)) {
        throw new functions.https.HttpsError(
          "invalid-argument",
          "result는 success 또는 failed만 허용됩니다."
        );
      }

      const uid = request.auth.uid;
      await enforceRateLimit({
        teamId,
        uid,
        action: "reportReservationResult",
        limit: 30,
        windowSeconds: 60,
      });

      return runIdempotent({
        teamId,
        uid,
        action: "reportReservationResult",
        requestId,
        handler: async () => {
        const db = admin.firestore();
        const noticeRef = db.collection("teams").doc(teamId).collection("reservation_notices").doc(noticeId);

        await db.runTransaction(async (tx) => {
          const noticeSnap = await tx.get(noticeRef);
          if (!noticeSnap.exists) {
            throw new functions.https.HttpsError("not-found", "예약 공지가 존재하지 않습니다.");
          }

          const data = noticeSnap.data() || {};
          const slots = ((data.slots as unknown[]) || []).map((e) => ({ ...(e as Record<string, unknown>) }));
          const slotIndex = slots.findIndex((s) => s.groundId === groundId);
          if (slotIndex < 0) {
            throw new functions.https.HttpsError("not-found", "해당 구장을 찾을 수 없습니다.");
          }

          const slot = slots[slotIndex];
          const managers = Array.isArray(slot.managers) ? slot.managers as string[] : [];
          if (!managers.includes(uid)) {
            throw new functions.https.HttpsError("permission-denied", "해당 구장 담당자가 아닙니다.");
          }
          if (slot.result === "success") {
            throw new functions.https.HttpsError("failed-precondition", "이미 예약 성공 처리되었습니다.");
          }

          slot.result = result;
          slot.successBy = uid;
          slot.successAt = admin.firestore.FieldValue.serverTimestamp();
          slots[slotIndex] = slot;

          const allReported = slots.every((s) => s.result === "success" || s.result === "failed");
          tx.update(noticeRef, {
            slots,
            ...(allReported ? { status: "completed" } : {}),
          });
        });

        if (result === "success") {
          const membersSnap = await db
            .collection("teams")
            .doc(teamId)
            .collection("members")
            .where("status", "==", "active")
            .get();
          const toUserIds = membersSnap.docs.map((d) => d.id);

          if (toUserIds.length > 0) {
            const noticeSnap = await noticeRef.get();
            const noticeData = noticeSnap.data() || {};
            const targetDate = noticeData.targetDate instanceof admin.firestore.Timestamp
              ? noticeData.targetDate.toDate()
              : null;
            const dateStr = targetDate ? `${targetDate.getMonth() + 1}/${targetDate.getDate()}` : "";
            const slots = ((noticeData.slots as unknown[]) || []) as Array<Record<string, unknown>>;
            const currentSlot = slots.find((s) => s.groundId === groundId);
            const groundName = (currentSlot?.groundName as string | undefined) || groundId;
            const reservedForType = (noticeData.reservedForType as string | undefined) || "class";
            const typeLabel = reservedForType === "class" ? "수업" : "매치";

            const actorSnap = await db.collection("teams").doc(teamId).collection("members").doc(uid).get();
            const actor = actorSnap.data() || {};
            const userName = (actor.uniformName as string | undefined)
              || (actor.name as string | undefined)
              || uid;

            await db.collection("teams").doc(teamId).collection("notifications").add({
              title: "구장 예약 성공",
              message: `${userName}님이 ${dateStr} ${typeLabel} · ${groundName} 예약 성공!`,
              type: "reservationSuccess",
              relatedId: noticeId,
              toUserId: toUserIds,
              isSent: false,
              sendAt: admin.firestore.FieldValue.serverTimestamp(),
              createdAt: admin.firestore.FieldValue.serverTimestamp(),
              createdBy: "system",
            });
          }
        }

        await appendAuditLog({
          teamId,
          actorUid: uid,
          action: "reservation_result_report",
          targetType: "reservation_notice",
          targetId: noticeId,
          after: {
            groundId,
            result,
          },
        });

        return { ok: true };
        },
      });
    } catch (error) {
      const code = error instanceof functions.https.HttpsError ? error.code : "internal";
      await recordFailureMetric({
        teamId,
        action: "reportReservationResult",
        errorCode: code,
      });
      throw error;
    }
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
        .collection("member_tokens")
        .limit(500)
        .get();

      const activeMembersSnap = await db
        .collection("teams")
        .doc(teamId)
        .collection("members")
        .where("status", "==", "active")
        .get();
      const activeMemberIds = new Set(activeMembersSnap.docs.map((d) => d.id));

      const tokens: string[] = [];
      membersSnap.docs.forEach((d) => {
        if (!activeMemberIds.has(d.id)) return;
        const isActiveToken = d.data()?.active as boolean | undefined;
        if (isActiveToken === false) return;
        const token = d.data()?.fcmToken as string | undefined;
        if (token) {
          tokens.push(token);
        }
      });

      // 마이그레이션 기간: member_tokens가 비어 있으면 기존 members.fcmToken 폴백
      if (tokens.length == 0) {
        activeMembersSnap.docs.forEach((d) => {
          const token = d.data()?.fcmToken as string | undefined;
          if (token) {
            tokens.push(token);
          }
        });
      }

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

/**
 * 경기/수업 날씨 스냅샷 저장
 * - 10분마다 실행, 시작시각 기준 약 24시간 전/3시간 전 문서를 갱신
 * - lat/lng가 있는 문서만 대상
 */
export const weatherSnapshotScheduled = functions.pubsub
  .schedule("every 10 minutes")
  .timeZone("Asia/Seoul")
  .onRun(async () => {
    const db = admin.firestore();
    const teamsSnap = await db.collection("teams").get();
    const now = new Date();

    for (const teamDoc of teamsSnap.docs) {
      const teamId = teamDoc.id;
      for (const beforeHours of [24, 3]) {
        const matchUpdated = await updateWeatherForCollection({
          teamId,
          collection: "matches",
          beforeHours,
          now,
        });
        const eventUpdated = await updateWeatherForCollection({
          teamId,
          collection: "events",
          beforeHours,
          now,
        });
        functions.logger.info("weather snapshot updated", {
          teamId,
          beforeHours,
          matchUpdated,
          eventUpdated,
        });
      }
    }
    return null;
  });
