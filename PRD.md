# Product Requirements Document

## 1. User Journey
- **Member:** Check schedule -> Vote Attendance (On-time/Late/Absent) -> Pay Dues.
- **Treasurer:** Check Unpaid List -> Send "Nudge" Notification -> Confirm Deposit.
- **Coach:** Check Attendance -> Set Lineup -> Log Match Results.

## 2. Key Features
### A. Monthly Cycle
- **20th:** System drafts "Next Month Registration Notice".
- **25th:** Registration opens.
- **26th:** Match voting opens.
- **27th:** Class voting opens.

### B. Match Management
- **Pre-match:** Auto-confirm when 7 players join.
- **In-match:** Real-time scoreboard & substitution logs.
- **Post-match:** MVP voting & Expense settlement.

### C. Variable Management
- **Lateness:** User MUST select "Late Time" (e.g., 15 mins).
- **Absence:** User MUST provide a reason.
- **Tasks:** "Who brings the ball?" checklist.

## 3. Notifications
- **Type:** Targeted Push (FCM).
- **Logic:**
  - "Nudge" only unpaid members.
  - "Alarm" for court reservation (Mon/Thu 23:30).