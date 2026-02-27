# Firestore Schema Design (최종 확정)

**핵심 원칙:** 
- ✅ **모든 운영 데이터는 `teams/{teamId}` 하위에만 존재**
- ✅ **루트에는 글로벌 공유 데이터만** (`teams_public`)
- ✅ **명확한 계층 구조로 일관성 유지**

---

## 🎯 구조 원칙

### 📍 위치 결정 기준

| 데이터 종류 | 위치 | 이유 |
|------------|------|------|
| **팀 운영 데이터** | `teams/{teamId}/...` | 멀티테넌트 격리 필수 |
| **팀 검색용 공개 정보** | `teams_public/{teamId}` | 온보딩 시 검색용 |

### 🔒 보안 규칙
- 모든 쿼리는 `teamId`로 필터링 필수
- 다른 팀 데이터 접근 불가능하도록 설계

---

## 📂 전체 구조 개요

```
루트 (Root)
├── teams_public/{teamId}          [글로벌 공유 - 검색용]
│
└── teams/{teamId}                 [모든 운영 데이터]
    ├── members/{memberId}         [멤버 관리]
    ├── matches/{matchId}           [경기 관리 - 복잡한 구조]
    │   └── rounds/{roundId}        [라운드별 정보]
    │       └── records/{recordId}  [골/교체 등 실시간 기록]
    ├── events/{eventId}            [이벤트 관리 - 단순 이벤트만]
    ├── grounds/{groundId}          [경기장 관리]
    ├── match_media/{mediaId}       [경기 영상]
    ├── feedbacks/{feedbackId}     [피드백/건의]
    ├── fees/{feeId}                [회비/수업비 통합]
    ├── polls/{pollId}              [투표]
    ├── posts/{postId}              [게시글]
    ├── registrations/{regId}       [등록 정보]
    ├── reservations/{resId}        [경기장 예약]
    ├── notifications/{notifId}     [알림]
    ├── settings/{settingId}        [팀 설정]
    └── transactions/{txId}        [거래 내역]
```

---

## 1. 글로벌 공유 데이터

### 1.1 `teams_public/{teamId}`
**용도:** 팀 검색용 공개 정보 (온보딩)

**필드:**
- `teamId`: String
- `name`: String
- `logoUrl`: String
- `region`: String (예: "서울", "경기")
- `intro`: String

**인덱스:**
- `region` (ascending)
- `name` (ascending)

---

## 2. 팀 운영 데이터 (`teams/{teamId}`)

### 2.1 팀 기본 정보

#### `teams/{teamId}` (문서)
**필드:**
- `teamId`: String (문서 ID와 동일)
- `name`: String (예: "영원FC")
- `teamColor`: String (예: "#2196F3")
- `teamLogoUrl`: String
- `captainName`: String (예: "정상하")
- `captainContact`: String (예: "010-1234-5678")
- `memo`: String (예: "우리는 영원!")
- `isOurTeam`: Boolean
- `createdAt`: Timestamp

---

### 2.2 멤버 관리

#### `teams/{teamId}/members/{memberId}`
**필드:**
- `memberId`: String (문서 ID와 동일)
- `name`: String (예: "염지수")
- `number`: Number (등번호, 예: 28)
- `uniformName`: String (예: "ZIGU")
- `phone`: String (예: "010-5015-7339")
- `email`: String (예: "yjsoo7339@gmail.com")
- `photoUrl`: String
- `birthday`: String (예: "1997-04-28")
- `homeAddress`: String
- `workAddress`: String
- `department`: String (예: "수업관리팀", "운영팀", "경기관리/대외협력팀", "미정")
- `role`: String ('일반' | '운영진' | '총무')
- `status`: String ('active' | 'pending' | 'rejected' | 'left')
- `isAdmin`: Boolean
- `joinedAt`: Timestamp
- `enrolledAt`: Timestamp
- `memo`: String (관리자 메모)
- `fcmToken`: String (FCM 푸시 알림용, 로그인 시 저장)

**인덱스:**
- `status` (ascending)
- `role` (ascending)
- `status` + `role` (composite)

---

### 2.3 경기 관리

**⚠️ 중요:** 경기는 `events`와 별도 컬렉션입니다.
- **이유:** 경기는 `rounds` → `records` 같은 복잡한 서브컬렉션 구조 필요
- **구조:** `matches/{matchId}/rounds/{roundId}/records/{recordId}`
- **용도:** 실시간 경기 기록(골, 교체 등) 관리

#### `teams/{teamId}/matches/{matchId}`
**필드:**
- `matchType`: String ('regular' | 'irregular') — 정기/비정기 구분
- `date`: Timestamp
- `startTime`: String (예: "18:00")
- `endTime`: String (예: "20:00")
- `location`: String (예: "석수 다목적구장")
- `status`: String ('pending' | 'fixed' | 'confirmed' | 'inProgress' | 'finished' | 'cancelled')
- `gameStatus`: String ('notStarted' | 'playing' | 'finished')
- `minPlayers`: Number (경기 성사 최소 인원, 기본값 7)
- `isTimeConfirmed`: Boolean (시간 확정 여부, 기본값 false)
- `opponent`: Map — 상대팀 정보
  - `teamId`: String (opponents 컬렉션 참조)
  - `name`: String (예: "스마일리")
  - `contact`: String (연락처)
  - `status`: String ('seeking' | 'confirmed')
- `registerStart`: Timestamp
- `registerEnd`: Timestamp
- `participants`: Array<String> (팀 이름 배열)
- `attendees`: Array<String> (참석자 UID 배열)
- `absentees`: Array<String> (불참자 UID 배열)
- `absenceReasons`: Map — 불참 사유 { uid: { reason, timestamp } }
- `ballBringers`: Array<String> — 공 가져가기 자원자 UID ("저도 들고가요" 방식)
- `createdBy`: String (등록자 UID)
- `createdAt`: Timestamp
- `updatedAt`: Timestamp
- ~~`teamName`~~: String (deprecated → `opponent.name` 사용)
- ~~`recruitStatus`~~: String (deprecated → `opponent.status` 사용)

**상태 전이:**
- `pending` → `fixed` (attendees >= minPlayers 시 자동)
- `fixed` → `pending` (attendees < minPlayers 시 자동 롤백)
- `fixed`/`confirmed` → `inProgress` (경기 시작)
- `inProgress` → `finished` (경기 종료)
- 어떤 상태든 → `cancelled` (취소)

**서브컬렉션:**
- `rounds/{roundId}`

**인덱스:**
- `date` (descending)
- `status` (ascending)
- `matchType` (ascending)
- `date` + `status` (composite)
- `matchType` + `date` (composite)

---

#### `teams/{teamId}/matches/{matchId}/rounds/{roundId}`
**필드:**
- `roundIndex`: Number (예: 1)
- `status`: String ('not_started' | 'playing' | 'finished')
- `startTime`: Timestamp
- `endTime`: Timestamp
- `createdAt`: Timestamp
- `createdBy`: String

**서브컬렉션:**
- `records/{recordId}`

**인덱스:**
- `roundIndex` (ascending)
- `status` (ascending)

---

#### `teams/{teamId}/matches/{matchId}/rounds/{roundId}/records/{recordId}`
**공통 필드:**
- `type`: String ('goal' | 'substitution' | 'card' | 'assist')
- `teamType`: String ('our' | 'opponent')
- `timeOffset`: Number (초 단위)
- `timestamp`: Timestamp
- `createdBy`: String

**골 기록 (`type: "goal"`):**
- `playerId`: String
- `playerName`: String
- `playerNumber`: Number
- `assistPlayerId`: String
- `assistPlayerName`: String
- `goalType`: String (예: "PK")
- `isOwnGoal`: Boolean
- `scoreAfterGoal`: Number

**교체 기록 (`type: "substitution"`):**
- `inPlayerId`: String
- `inPlayerName`: String
- `inPlayerNumber`: Number
- `outPlayerId`: String
- `outPlayerName`: String
- `outPlayerNumber`: Number

**인덱스:**
- `roundId` (ascending)
- `type` (ascending)
- `timestamp` (descending)
- `roundId` + `timestamp` (composite)

---

### 2.4 이벤트 관리 (수업/모임)

#### `teams/{teamId}/events/{eventId}`
**설명:** 수업, 모임 등 단순 이벤트 관리

**⚠️ 중요:** 경기는 `matches` 컬렉션을 별도로 사용합니다.

**구분 기준:**
- ✅ **`events` 사용:** 수업, MT, 모임 등 단순 이벤트
- ✅ **`matches` 사용:** 경기 (rounds/records 구조 필요)

**이유:**
- 경기는 `rounds` → `records` 같은 복잡한 서브컬렉션 구조 필요
- 실시간 경기 기록(골, 교체 등) 관리가 복잡함
- 단순 이벤트와 구조가 완전히 다름

**필드:**
- `type`: String ('class' | 'social' | 'tournament')  // 'match'는 제외!
- `title`: String (예: "8월 MT")
- `description`: String
- `date`: String (예: "2025-08-17")
- `startTime`: String (예: "10:00")
- `endTime`: String (예: "18:00")
- `location`: String
- `status`: String ('active' | 'confirmed' | 'finished' | 'cancelled')
- `registerStart`: Timestamp
- `registerEnd`: Timestamp
- `fromPoll`: Boolean
- `pollId`: String
- `createdBy`: String
- `createdAt`: Timestamp
- `updatedAt`: Timestamp

**수업 전용 필드 (`type: "class"`):**
- `attendance`: Map
  - `present`: Number
  - `absent`: Number
- `attendees`: Array<Map>
  - `userId`: String
  - `status`: String ('attending' | 'late' | 'absent')
  - `reason`: String
  - `updatedAt`: Timestamp
- `comments`: Array<Map>
  - `userId`: String
  - `text`: String

**이벤트 전용 필드 (`type: "social"`):**
- `eventType`: String (예: "MT")
- `attendees`: Array<Map>
  - `userId`: String
  - `userName`: String
  - `number`: Number
- `comments`: Array<String>

**인덱스:**
- `type` (ascending)
- `date` (descending)
- `status` (ascending)
- `type` + `date` (composite)
- `type` + `status` (composite)

---

### 2.5 경기장 관리

#### `teams/{teamId}/grounds/{groundId}`
**필드:**
- `groundId`: String (예: "독산역_2-2")
- `name`: String (예: "소규모 축구장 2-2")
- `url`: String
- `address`: String (주소, 예: 서울 금천구 가산동 562-3)
- `active`: Boolean
- `priority`: Number (예: 1)
- `managers`: Array<String> (관리자 ID 배열)

**인덱스:**
- `active` (ascending)
- `priority` (ascending)

---

### 2.6 경기 영상

#### `teams/{teamId}/match_media/{mediaId}`
**필드:**
- `matchId`: String
- `opponentTeamName`: String (예: "홍대볼러즈")
- `videoUrls`: Array<String>
- `playlistUrl`: String
- `uploadedBy`: String
- `createdAt`: Timestamp

**인덱스:**
- `matchId` (ascending)
- `createdAt` (descending)

---

### 2.7 피드백

#### `teams/{teamId}/feedbacks/{feedbackId}`
**필드:**
- `userId`: String
- `type`: String (예: "운영 관련")
- `content`: String
- `status`: String ('new' | 'resolved' | 'rejected')
- `resolvedBy`: String
- `resolvedAt`: Timestamp
- `createdAt`: Timestamp

**인덱스:**
- `status` (ascending)
- `createdAt` (descending)
- `status` + `createdAt` (composite)

---

### 2.8 회비/수업비 통합

#### `teams/{teamId}/fees/{feeId}`
**설명:** 회비와 수업비 통합 관리

**필드:**
- `feeType`: String ('membership' | 'lesson')
- `name`: String (예: "정기 회비", "2025년 하반기 회비")
- `amount`: Number (예: 5000)
- `periodStart`: Timestamp
- `periodEnd`: Timestamp
- `memo`: String
- `isActive`: Boolean
- `createdBy`: String
- `createdAt`: Timestamp

**인덱스:**
- `feeType` (ascending)
- `isActive` (ascending)
- `periodStart` (descending)
- `feeType` + `isActive` (composite)

---

### 2.9 커뮤니티

#### `teams/{teamId}/polls/{pollId}`
**필드:**
- `title`: String (예: "8월 MT 일정 투표")
- `description`: String
- `type`: String ('text' | 'date' | 'option')
- `category`: String ('membership' | 'attendance' | 'match' | 'general') — 월별 등록(20~24일) / 일자별 참석(25~말일)
- `targetMonth`: String (yyyy-MM, 월별 등록/일자별 참석용)
- `anonymous`: Boolean
- `canChangeVote`: Boolean
- `maxSelections`: Number
- `showResultBeforeDeadline`: Boolean
- `isActive`: Boolean
- `expiresAt`: Timestamp
- `resultFinalizedAt`: Timestamp
- `linkedEventId`: String
- `createdBy`: String
- `createdAt`: Timestamp
- `options`: Array<Map>
  - `id`: String
  - `text`: String
  - `date`: Timestamp (날짜형 투표인 경우)
  - `voteCount`: Number
  - `votes`: Array<String>

**인덱스:**
- `isActive` (ascending)
- `expiresAt` (ascending)
- `createdAt` (descending)
- `isActive` + `expiresAt` (composite)

---

#### `teams/{teamId}/posts/{postId}`
**필드:**
- `title`: String
- `content`: String
- `category`: String (예: "공지")
- `authorId`: String
- `pollId`: String (연결된 투표 ID)
- `isPinned`: Boolean
- `publishAt`: Timestamp
- `createdAt`: Timestamp

**인덱스:**
- `category` (ascending)
- `isPinned` (descending)
- `publishAt` (descending)
- `isPinned` + `publishAt` (composite)

---

### 2.10 등록 관리

#### `teams/{teamId}/registrations/{registrationId}`
**필드:**
- `eventId`: String (시즌/월: yyyy-MM 또는 eventId)
- `userId`: String
- `userName`: String
- `uniformNo`: Number
- `photoUrl`: String
- `type`: String ('class' | 'match' | 'event')
- `status`: String ('registered' | 'cancelled' | 'attended' | 'absent' | 'pending' | 'paid')
- `membershipStatus`: String ('registered' | 'paused' | 'exempt') — 월별 등록 투표 결과 (등록 5만/휴회 2만/미등록 0)
- `createdAt`: Timestamp
- `updatedAt`: Timestamp

**인덱스:**
- `eventId` (ascending)
- `userId` (ascending)
- `status` (ascending)
- `eventId` + `status` (composite)
- `userId` + `status` (composite)

---

### 2.11 예약 관리

#### `teams/{teamId}/reservations/{reservationId}`
**필드:**
- `groundId`: String
- `reservedForType`: String ('class' | 'match' | 'event')
- `reservedForId`: String
- `date`: Timestamp
- `startTime`: String
- `endTime`: String
- `status`: String ('reserved' | 'cancelled' | 'completed')
- `paymentStatus`: String ('paid' | 'unpaid' | 'refunded')
- `reservedBy`: String
- `memo`: String
- `createdAt`: Timestamp

**인덱스:**
- `groundId` (ascending)
- `date` (ascending)
- `status` (ascending)
- `groundId` + `date` (composite)
- `date` + `status` (composite)

---

### 2.11-1 예약 공지 (구장 예약 안내)

#### `teams/{teamId}/reservation_notices/{noticeId}`
**설명:** 구장 예약 공지 (예약 시도 날짜 자동 계산, 구장별 담당자 배정, 성공/실패 결과 보고)

**필드:**
- `targetDate`: Timestamp (이용일)
- `targetStartTime`: String (예: "20:00")
- `targetEndTime`: String (예: "22:00")
- `reservedForType`: String ('class' | 'match')
- `reservedForId`: String? (eventId 또는 matchId)
- `venueType`: String ('geumcheon' | 'seoul')
- `openAt`: Timestamp (예약 시도 시점)
- `slots`: Array<{groundId, groundName, address, url, managers, result, successBy, successAt}>
- `fallback`: Map? (대안 예약: title, openAtText, url, fee, memo)
- `status`: String ('pending' | 'published' | 'completed')
- `createdBy`: String
- `publishedAt`: Timestamp?
- `createdAt`: Timestamp

**인덱스:**
- `targetDate` (ascending)

---

### 2.12 알림

#### `teams/{teamId}/notifications/{notificationId}`
**필드:**
- `title`: String
- `message`: String
- `type`: String (예: "pollCreated")
- `relatedId`: String
- `toUserId`: Array<String>
- `isSent`: Boolean
- `sendAt`: Timestamp
- `createdAt`: Timestamp

**인덱스:**
- `isSent` (ascending)
- `sendAt` (ascending)
- `createdAt` (descending)
- `isSent` + `sendAt` (composite)

---

### 2.13 팀 설정

#### `teams/{teamId}/settings/{settingId}`
**필드:**
- `type`: String ('attendanceManager' | 'membershipManager' | 'reservationNoticeManager')
- `userIds`: Array<String>

**인덱스:**
- `type` (ascending)

---

### 2.14 거래 내역

#### `teams/{teamId}/transactions/{transactionId}`
**필드:**
- `type`: String ('payment' | 'refund' | 'fee')
- `amount`: Number
- `userId`: String
- `description`: String
- `status`: String ('pending' | 'completed' | 'failed')
- `createdAt`: Timestamp
- `completedAt`: Timestamp

**인덱스:**
- `userId` (ascending)
- `status` (ascending)
- `createdAt` (descending)
- `userId` + `status` (composite)

---

## 3. 데이터 관계도

```
teams_public/{teamId}                    [검색용 공개 정보]
    ↓ (참조)
teams/{teamId}                          [모든 운영 데이터]
    ├── members/{memberId}              [멤버]
    ├── matches/{matchId}               [경기 - 복잡한 구조]
    │   └── rounds/{roundId}            [라운드]
    │       └── records/{recordId}     [골/교체 기록]
    ├── events/{eventId}                [이벤트 - 단순 이벤트만]
    ├── grounds/{groundId}              [경기장]
    ├── match_media/{mediaId}           [영상]
    ├── feedbacks/{feedbackId}          [피드백]
    ├── fees/{feeId}                    [회비/수업비]
    ├── polls/{pollId}                  [투표]
    ├── posts/{postId}                  [게시글]
    ├── registrations/{regId}           [등록]
    ├── reservations/{resId}            [예약]
    ├── notifications/{notifId}         [알림]
    ├── settings/{settingId}            [설정]
    └── transactions/{txId}             [거래]
```

---

## 4. 실제 사용 가능 여부 검증

### ✅ 이 구조가 작동하는 이유

#### 1. **Firestore 제한사항 고려**
- ✅ 서브컬렉션 쿼리는 부모 문서를 거쳐야 함 → **이 구조가 정확히 그렇게 설계됨**
- ✅ 복합 쿼리 제한 → **인덱스 전략으로 해결**
- ✅ 쿼리 경로가 명확 → `teams/{teamId}/members` 등

#### 2. **실제 쿼리 예시**

```dart
// ✅ 멤버 조회 (자동 팀 격리)
firestore
  .collection('teams')
  .doc(teamId)
  .collection('members')
  .where('status', isEqualTo: 'active')
  .get();

// ✅ 경기 조회 (자동 팀 격리)
firestore
  .collection('teams')
  .doc(teamId)
  .collection('matches')
  .where('date', isGreaterThan: DateTime.now())
  .orderBy('date')
  .get();

// ✅ 이벤트 조회 (타입 필터링)
firestore
  .collection('teams')
  .doc(teamId)
  .collection('events')
  .where('type', isEqualTo: 'class')
  .where('status', isEqualTo: 'active')
  .get();
```

#### 3. **보안 규칙 자동 적용**

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // 팀 운영 데이터는 해당 팀 멤버만 접근 가능
    match /teams/{teamId}/{document=**} {
      allow read, write: if request.auth != null 
        && exists(/databases/$(database)/documents/teams/$(teamId)/members/$(request.auth.uid))
        && get(/databases/$(database)/documents/teams/$(teamId)/members/$(request.auth.uid)).data.status == 'active';
    }
  }
}
```

**장점:** 쿼리 경로 자체가 `teams/{teamId}`로 시작하므로, 보안 규칙이 자동으로 적용됨

---

### ⚠️ 주의사항

#### 1. **서브컬렉션 쿼리 제한**
- ❌ `teams/{teamId}/members`와 `teams/{teamId}/matches`를 동시에 쿼리 불가
- ✅ 해결: 각각 별도 쿼리 실행 (이미 팀별로 격리되어 있음)

#### 2. **인덱스 관리**
- ⚠️ 복합 인덱스가 많아짐
- ✅ 해결: 실제 사용 패턴에 맞춰 인덱스 생성

#### 3. **마이그레이션 필요**
- ⚠️ 기존 데이터를 새 구조로 이동 필요
- ✅ 해결: 점진적 마이그레이션 가능

---

## 5. 최종 판단

### ✅ 이 구조를 추천하는 이유

1. **멀티테넌트 격리 완벽**
   - 쿼리 경로 자체가 팀별 격리 보장
   - 보안 규칙 적용이 간단

2. **일관성 확보**
   - 모든 운영 데이터가 동일한 패턴
   - 개발자가 이해하기 쉬움

3. **확장성**
   - 새 팀 추가 시 자동 격리
   - 새 컬렉션 추가가 쉬움

4. **Firestore 베스트 프랙티스 준수**
   - 서브컬렉션 활용
   - 인덱스 전략 명확

### 🎯 결론

**이 구조는 실제로 사용 가능하며, Firestore의 제한사항을 고려한 최적의 설계입니다.**

다만, 기존 데이터 마이그레이션이 필요하므로 점진적으로 진행하는 것을 권장합니다.

---

## 6. matches vs events 구분 가이드

### 📊 구조 비교

| 항목 | `matches` | `events` |
|------|-----------|----------|
| **용도** | 경기 전용 | 수업/모임 등 단순 이벤트 |
| **구조** | 복잡 (rounds → records) | 단순 (문서만) |
| **서브컬렉션** | ✅ 있음 (rounds, records) | ❌ 없음 |
| **실시간 기록** | ✅ 필요 (골, 교체 등) | ❌ 불필요 |
| **예시** | 정식 경기, 친선전 | 수업, MT, 모임 |

### 🎯 사용 가이드

**`matches` 사용:**
- ✅ 정식 경기 (라운드별 기록 필요)
- ✅ 친선전 (골/교체 기록 필요)
- ✅ 토너먼트 (복잡한 구조 필요)

**`events` 사용:**
- ✅ 수업/훈련 (`type: 'class'`)
- ✅ MT/모임 (`type: 'social'`)
- ✅ 단순 일정 (`type: 'tournament'`)

---

## 7. 마이그레이션 전략

### 단계별 마이그레이션

**1단계: 새 데이터는 새 구조로 저장**
- 기존 데이터는 유지
- 새 데이터만 `teams/{teamId}` 하위로 저장

**2단계: 읽기 로직 통합**
- 기존 구조와 새 구조 모두 읽기 가능하도록 구현
- 우선순위: 새 구조 → 기존 구조

**3단계: 기존 데이터 마이그레이션**
- 배치 작업으로 기존 데이터 이동
- 마이그레이션 완료 후 기존 구조 제거

**⚠️ 주의사항:**
- `matches`는 구조가 복잡하므로 별도로 마이그레이션
- `classes`는 `events`로 이동 (type: 'class')
- `events`는 `events`로 이동 (type: 'social', 경기 제외)

---

**작성일:** 2025-01-18  
**버전:** 4.0 (실제 사용 가능 여부 검증 완료)
