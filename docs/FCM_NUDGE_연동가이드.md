# FCM 미납자 Nudge 연동 가이드

> 2026-02-26 기준

---

## 1. 현재 구현 상태

### 클라이언트 (Flutter) ✅
- `firebase_messaging` 패키지 추가
- Android: `POST_NOTIFICATIONS` 권한, `google-services.json` (기존)
- iOS: `UIBackgroundModes` (remote-notification, fetch)
- FCM 초기화: `FcmInitializer` 위젯
- 토큰 저장: `teams/{teamId}/members/{memberId}.fcmToken`
- MainShell 진입 시 `syncTokenToFirestore()` 호출

### Firestore 스키마
- `teams/{teamId}/members/{memberId}` 에 `fcmToken: String?` 필드 추가됨

---

## 2. Nudge 전송을 위한 Cloud Functions

### 필요한 함수: `sendNudgeToUnpaid`

**트리거:** HTTP 호출 (총무가 "미납자 알림" 버튼 탭 시)

**입력:**
- `teamId`: String
- `seasonId`: String (예: "2026-02", feeId 또는 registrations season)

**처리:**
1. `teams/{teamId}/registrations` 또는 `seasons/{seasonId}/registrations` 에서 `status != 'paid'` 인 등록 조회
2. 각 등록의 `userId`로 `teams/{teamId}/members/{userId}` 에서 `fcmToken` 조회
3. FCM Admin SDK로 해당 토큰들에 메시지 전송

**예시 (Node.js):**
```javascript
const functions = require('firebase-functions');
const admin = require('firebase-admin');

exports.sendNudgeToUnpaid = functions.https.onCall(async (data, context) => {
  if (!context.auth) throw new functions.https.HttpsError('unauthenticated', '로그인 필요');
  
  const { teamId, seasonId } = data;
  const db = admin.firestore();
  
  // 미납자 UID 목록 조회
  const regs = await db.collection('teams').doc(teamId)
    .collection('registrations')  // 또는 seasons/{seasonId}/registrations
    .where('status', '!=', 'paid')
    .get();
  
  const unpaidUids = regs.docs.map(d => d.data().userId).filter(Boolean);
  if (unpaidUids.length === 0) return { sent: 0 };
  
  // FCM 토큰 조회
  const tokens = [];
  for (const uid of unpaidUids) {
    const member = await db.collection('teams').doc(teamId)
      .collection('members').doc(uid).get();
    const token = member.data()?.fcmToken;
    if (token) tokens.push(token);
  }
  
  if (tokens.length === 0) return { sent: 0 };
  
  await admin.messaging().sendEachForMulticast({
    tokens,
    notification: {
      title: '회비 납부 안내',
      body: '이번 달 회비 납부를 확인해 주세요.',
    },
    data: { type: 'nudge', teamId, seasonId },
  });
  
  return { sent: tokens.length };
});
```

---

## 3. 클라이언트에서 호출

`fee_management_page.dart`의 "미납자 알림" 버튼에서:

```dart
// Cloud Functions 호출 (firebase_functions 패키지 필요)
final callable = FirebaseFunctions.instance.httpsCallable('sendNudgeToUnpaid');
await callable.call({'teamId': teamId, 'seasonId': feeId});
```

또는 REST API로 Cloud Function URL 호출.

---

## 4. Court Alarm (Mon/Thu 23:30)

- Cloud Scheduler로 매주 월/목 23:30에 실행
- `teams/{teamId}` 중 해당일 예약이 있는 팀의 멤버들에게 알림
- `reservations` 컬렉션 조회 후 FCM 발송

---

## 5. 다음 단계

1. `firebase-functions` 프로젝트 초기화
2. `sendNudgeToUnpaid` 함수 배포
3. 클라이언트에 `cloud_functions` 패키지 추가 후 호출 연동
4. (선택) Court Alarm용 스케줄 함수
