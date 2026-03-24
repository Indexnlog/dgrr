import { readFile } from "node:fs/promises";
import path from "node:path";
import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
  RulesTestEnvironment,
} from "@firebase/rules-unit-testing";
import { doc, getDoc, setDoc, updateDoc } from "firebase/firestore";

const PROJECT_ID = "dgrr-app-rules-test";
const TEAM_ID = "team_alpha";
const ADMIN_UID = "admin_user";
const TREASURER_UID = "treasurer_user";
const MEMBER_UID = "member_user";

async function seedBaseData(env: RulesTestEnvironment): Promise<void> {
  await env.withSecurityRulesDisabled(async (context) => {
    const db = context.firestore();

    // 역할/상태 시드
    await setDoc(doc(db, `teams/${TEAM_ID}/members/${ADMIN_UID}`), {
      memberId: ADMIN_UID,
      role: "운영진",
      status: "active",
    });
    await setDoc(doc(db, `teams/${TEAM_ID}/members/${TREASURER_UID}`), {
      memberId: TREASURER_UID,
      role: "총무",
      status: "active",
    });
    await setDoc(doc(db, `teams/${TEAM_ID}/members/${MEMBER_UID}`), {
      memberId: MEMBER_UID,
      role: "일반",
      status: "active",
      name: "테스트 멤버",
      uniformName: "테멤",
      number: 7,
      photoUrl: "",
      updatedAt: new Date(),
    });

    await setDoc(doc(db, `teams/${TEAM_ID}/registrations/reg_1`), {
      userId: MEMBER_UID,
      eventId: "2026-03",
      status: "pending",
      updatedAt: new Date(),
    });

    await setDoc(doc(db, `teams/${TEAM_ID}/notifications/noti_1`), {
      title: "테스트",
      message: "메시지",
      readBy: [],
      createdAt: new Date(),
    });

    await setDoc(doc(db, `teams/${TEAM_ID}/reservation_notices/notice_1`), {
      status: "published",
      slots: [
        {
          groundId: "g1",
          managers: [MEMBER_UID],
          result: "pending",
        },
      ],
      targetDate: new Date(),
      createdAt: new Date(),
    });
  });
}

async function run(): Promise<void> {
  const rulesPath = path.resolve(process.cwd(), "..", "firestore.rules");
  const rules = await readFile(rulesPath, "utf8");

  const env = await initializeTestEnvironment({
    projectId: PROJECT_ID,
    firestore: {
      host: "127.0.0.1",
      port: 8080,
      rules,
    },
  });

  try {
    await seedBaseData(env);

    const memberDb = env.authenticatedContext(MEMBER_UID).firestore();
    const treasurerDb = env.authenticatedContext(TREASURER_UID).firestore();

    // 1) 일반 멤버는 paid 상태 변경 불가
    await assertFails(
      updateDoc(doc(memberDb, `teams/${TEAM_ID}/registrations/reg_1`), {
        status: "paid",
      })
    );

    // 2) 총무는 paid 상태 변경 가능
    await assertSucceeds(
      updateDoc(doc(treasurerDb, `teams/${TEAM_ID}/registrations/reg_1`), {
        status: "paid",
      })
    );

    // 3) 일반 멤버는 notifications 생성 불가
    await assertFails(
      setDoc(doc(memberDb, `teams/${TEAM_ID}/notifications/noti_x`), {
        title: "금지",
        message: "직접 생성 금지",
      })
    );

    // 4) 일반 멤버는 notifications readBy 업데이트만 허용
    await assertSucceeds(
      updateDoc(doc(memberDb, `teams/${TEAM_ID}/notifications/noti_1`), {
        readBy: [MEMBER_UID],
      })
    );

    // 5) 일반 멤버는 reservation_notices.slots 직접 수정 불가
    await assertFails(
      updateDoc(doc(memberDb, `teams/${TEAM_ID}/reservation_notices/notice_1`), {
        slots: [],
      })
    );

    // 6) 본인 members 문서에서 허용 필드(name) 업데이트 가능
    await assertSucceeds(
      updateDoc(doc(memberDb, `teams/${TEAM_ID}/members/${MEMBER_UID}`), {
        name: "테스트 멤버2",
      })
    );

    // 7) 본인 members 문서에서 role 변경은 금지
    await assertFails(
      updateDoc(doc(memberDb, `teams/${TEAM_ID}/members/${MEMBER_UID}`), {
        role: "운영진",
      })
    );

    // 8) member_tokens는 본인 읽기 허용 / 타인 읽기 금지
    await env.withSecurityRulesDisabled(async (context) => {
      await setDoc(doc(context.firestore(), `teams/${TEAM_ID}/member_tokens/${MEMBER_UID}`), {
        fcmToken: "token_123",
        active: true,
      });
    });
    await assertSucceeds(
      getDoc(doc(memberDb, `teams/${TEAM_ID}/member_tokens/${MEMBER_UID}`))
    );
    await assertFails(
      getDoc(doc(treasurerDb, `teams/${TEAM_ID}/member_tokens/${MEMBER_UID}`))
    );

    console.log("✅ Firestore Rules smoke test passed");
  } finally {
    await env.cleanup();
  }
}

run().catch((error) => {
  console.error("❌ Firestore Rules smoke test failed");
  console.error(error);
  process.exit(1);
});
