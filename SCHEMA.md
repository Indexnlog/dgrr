# Firestore Schema Design (SaaS Optimized)

**Core Principle:** All operational data MUST reside under `teams/{teamId}`.

## 1. Team & Members
- `teams/{teamId}`
  - `profile`: { name, logoUrl, color, intro }
  - `stats`: { totalMatches, wins, draws, losses } (Aggregated)
  
  - **Sub-collection:** `members/{uid}`
    - `profile`: { name, uniformNumber, position, phone, photoUrl }
    - `role`: 'admin' | 'treasurer' | 'coach' | 'member'
    - `status`: 'active' | 'pending' | 'rejected' | 'left'
    - `joinedAt`: Timestamp

## 2. Integrated Event System (Calendar Core)
> Instead of separating classes/matches/events, use one `events` collection with `type`.

- `teams/{teamId}/events/{eventId}`
  - `type`: 'match' | 'class' | 'social' | 'tournament'
  - `status`: 'pending' | 'confirmed' | 'cancelled' | 'finished'
  - `dateTime`: { startAt, endAt }
  - `location`: { name, address, lat, lng }
  - `meta`:
    - `match`: { opponentId, opponentName, minPlayers }
    - `class`: { instructor, topic }
    - `cost`: Number (if applicable)
  
  - **Sub-collection:** `participants/{uid}`
    - `status`: 'attending' | 'late' | 'absent'
    - `lateMinutes`: Number (if late)
    - `absenceReason`: String (if absent)
    - `updatedAt`: Timestamp

## 3. Match Records (Real-time Game Data)
- `teams/{teamId}/matches/{matchId}` (Linked to eventId if needed, or use same ID)
  - `opponent`: { id, name, logoUrl }
  - `score`: { home: 0, away: 0 }
  - `lineup`: Array<Uid>
  
  - **Sub-collection:** `timeline/{recordId}`
    - `type`: 'goal' | 'assist' | 'sub_in' | 'sub_out' | 'card'
    - `timeOffsetSec`: Number
    - `player`: { uid, name, number } (Snapshot)
    - `scoreSnapshot`: { home, away }

## 4. Monthly Operations (Finance & Status)
- `teams/{teamId}/seasons/{yyyy-mm}`
  - `isClosed`: Boolean (Finance closed)
  
  - **Sub-collection:** `registrations/{uid}`
    - `statusType`: 'regular' | 'pause' | 'exempt'
    - `dues`: { amount, isPaid, paidAt, method }
    - `attendanceStats`: { classCount, matchCount }

## 5. Community & Admin
- `teams/{teamId}/posts/{postId}`
  - `type`: 'notice' | 'poll' | 'general'
  - `poll`: { options: [], multiSelect: Bool, expiresAt: Time } (If poll)
  
- `teams/{teamId}/notifications/{notifId}`
  - `targetGroup`: 'all' | 'admin' | 'unpaid_members'
  - `content`: { title, body, deepLink }
  - `scheduledAt`: Timestamp (For automated push)

## 6. Global Shared Data (Read-only for users)
- `teams_public/{teamId}`
  - `name`, `logoUrl`, `region`, `intro` (For onboarding search)