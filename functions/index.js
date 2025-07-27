// const functions = require("firebase-functions/v2"); // ✅ 사용하지 않으므로 제거
const admin = require("firebase-admin");
const {onSchedule} = require("firebase-functions/scheduler");

admin.initializeApp();
const db = admin.firestore();

// 매 5분마다 실행되는 스케줄 함수
exports.updateMatchStatuses = onSchedule("every 5 minutes", async (event) => {
  const now = new Date();
  const todayStr = now.toISOString().split("T")[0]; // yyyy-mm-dd
  const nowMinutes = now.getHours() * 60 + now.getMinutes();

  const snapshot = await db.collection("matches").get();
  const batch = db.batch();

  snapshot.forEach((doc) => {
    const data = doc.data();
    const dateField = data.date;
    const start = data.startTime;
    const end = data.endTime;

    if (!dateField || !start || !end) return;

    const dateObj = dateField.toDate();
    const dateStr = dateObj.toISOString().split("T")[0];

    // 오늘 경기만 상태 갱신
    if (dateStr === todayStr) {
      const [sh, sm] = start.split(":").map((n) => parseInt(n, 10));
      const [eh, em] = end.split(":").map((n) => parseInt(n, 10));
      const startMinutes = sh * 60 + sm;
      const endMinutes = eh * 60 + em;

      let newStatus = data.gameStatus;
      if (nowMinutes >= startMinutes && nowMinutes < endMinutes) {
        newStatus = "inProgress";
      } else if (nowMinutes >= endMinutes) {
        newStatus = "finished";
      } else {
        newStatus = "notStarted";
      }

      if (newStatus !== data.gameStatus) {
        console.log(
            `Updating ${doc.id} from ${data.gameStatus} → ${newStatus}`,
        );
        batch.update(doc.ref, {gameStatus: newStatus});
      }
    }
  });

  await batch.commit();
  console.log("✅ Match statuses updated!");
});
