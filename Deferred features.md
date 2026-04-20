# Ichiban App — Deferred Features

This file tracks features and behaviours that have been **designed and partially scaffolded
but not yet fully built**. Each entry includes enough context to implement it cold, without
needing to refer back to the original handover conversation.

**Rules — read before every session:**
- When a new handover document is uploaded: read this file FIRST. If any item can be built as part of that handover, build it, then **DELETE it from this file**.
- When any item is built for any reason: **DELETE it from this file immediately** after completion.
- When a new deferred item is identified during implementation: **ADD it here immediately**.
- This file must only ever contain things not yet built. Nothing completed stays here.

---

## 1. GDPR — Automatic Anonymisation (Cloud Function)

**Source:** Disciplines, Ranks & GDPR handover — Section 5.3
**Depends on:** Memberships feature (lapse date must be stored on membership record)
**Scope:** Backend / Firebase Cloud Functions — NOT Flutter

**What it is:**
A scheduled Cloud Function that runs daily and anonymises any lapsed member whose
personal data retention period has expired.

**Logic:**
- Find all profiles where `isActive = false` AND `isAnonymised = false`
- For each, find their most recent membership record and check the lapse date
- If `lapse date + gdprRetentionMonths` (from appSettings, default 12) ≤ today,
  trigger the same anonymisation process as the manual trigger above
- `gdprRetentionMonths` is stored in `appSettings/gdprRetentionMonths` ✅

**Note:** The Flutter app only needs to display the anonymised state correctly
(the `isAnonymised` field already exists on `Profile`). The Cloud Function
is entirely backend work.

---

## 3. GDPR — Data Export (Right of Access)

**Source:** Disciplines, Ranks & GDPR handover — Section 5.5
**Depends on:** Memberships, Enrollment, Grading, Attendance, Payments features
(all need to be built before a complete export is possible)
**Can be partially built now:** Profile-only export could be done immediately.

**What it is:**
Admin can export a full member record on request. The export includes:
- All profile fields
- All membership records
- All enrolment records
- All grading records
- All attendance records
- All payment records

**Format:** Admin chooses at export time: PDF, CSV, or both.

**Where to build it:**
- Add an 'Export Member Data' action on `ProfileDetailScreen`
- A bottom sheet or dialog lets admin choose PDF / CSV / Both
- Fetch all related records for the profile across all collections
- Generate the chosen format(s) and share/download
- Consider using `pdf` and `csv` packages (not yet in pubspec.yaml — add them)
- No sensitive data should be logged during export

---

## 4. Discipline Inactivity Enforcement (Grading only)

**Source:** Disciplines, Ranks & GDPR handover — Section 3
**Depends on:** Grading feature

**What is already built:**
- `isActive` flag on `Discipline` entity ✅
- `activeDisciplineListProvider` streams only active disciplines ✅
- The deactivation toggle + warning banner in `DisciplineFormScreen` ✅
- **Enrollment guard:** `EnrolStudentUseCase` throws if `discipline.isActive == false` ✅
- **Enrollment UI:** `EnrolDisciplineScreen` only shows active disciplines ✅
- **Attendance UI:** `CreateAttendanceSessionScreen` and `SelfCheckInScreen` filter to active disciplines via `activeDisciplineListProvider` ✅

**What still needs enforcing:**
- Grading: when triggering a grading event, only allow active disciplines (same pattern)

**Update (Grading feature built):** `CreateGradingEventScreen` already uses `activeDisciplineListProvider` for the discipline dropdown, so inactive disciplines are excluded from new event creation ✅. The remaining gap is that `CreateGradingEventUseCase` does not yet throw if a caller bypasses the UI with an inactive `disciplineId`. This is the outstanding enforcement gap.

Admin can still **view** inactive disciplines and their enrolled students for
historical reference — already supported via `disciplineListProvider`.

---

## 5. Minimum Attendance for Grading Enforcement

**Source:** Disciplines, Ranks & GDPR handover — Section 3
**Depends on:** Grading feature, Attendance feature

**What it is:**
Each rank has an optional `minAttendanceForGrading` integer field (already in the
`Rank` entity and stored in Firestore). Before a student can be put forward for
grading to a specific rank, their session attendance count for that discipline
must be ≥ `minAttendanceForGrading`.

**What is already built:**
- `minAttendanceForGrading` field on `Rank` entity ✅
- Field is editable in `RankFormScreen` ✅
- Stored in Firestore ✅

**What still needs building:**
In the Grading feature, when an admin selects a student and a target rank:
- Fetch the student's attendance count for the relevant discipline
- Compare against `rank.minAttendanceForGrading`
- If the student hasn't met the threshold, show a warning (not a hard block —
  admin can override with confirmation)

---

## 6. Student PIN — Behaviour When No PIN Set

**Source:** Auth feature (Phase 2)
**Depends on:** Nothing. Can be clarified with product owner and built now.

**What it is:**
The `pinHash` field on `Profile` is nullable. A student profile can exist without
a PIN set (e.g. newly created profiles, or profiles created before PIN was a feature).

**Current behaviour:**
The PIN entry screen (`/student/pin`) will receive a null `pinHash` and the
behaviour is undefined — it may crash or silently fail.

**What needs deciding / building:**
Agree with product owner on the flow, then implement:
- Option A: If no PIN is set, the student is asked to create one before proceeding
- Option B: Admin must set a PIN before the profile can be used on the student app
- Option C: A temporary default PIN is assigned at profile creation

`SetPinUseCase` already exists in `lib/domain/use_cases/profile/set_pin_use_case.dart` ✅

---

## 7. Membership Summary on Profile Detail

**Source:** Profiles handover
**Depends on:** Memberships feature

**What it is:**
The `ProfileDetailScreen` (`lib/presentation/features/profiles/profile_detail_screen.dart`)
has a placeholder "Membership summary coming in a future phase" section.

**What needs replacing:**
Once the Memberships feature is built, replace the placeholder with:
- Current membership type and status (active / lapsed / trial)
- Membership expiry / renewal date
- Quick link to the full membership record

---

## 8. Dashboard Screen

**Source:** App scaffold
**Depends on:** Multiple features (needs data from profiles, attendance, memberships)

**What it is:**
The admin dashboard (`/admin/dashboard`) is currently a `_PlaceholderScreen`.
No handover document has been received for this feature yet.

---

## 9. Student App Screens (Attendance History)

**Source:** App scaffold
**Depends on:** Nothing blocking

**What they are:**
The following student route is currently a `_PlaceholderScreen`:
- `/student/attendance` — student's own attendance history

`/student/home` (StudentHomeScreen), `/student/checkin` (SelfCheckInScreen), and `/student/grades`
(StudentGradesScreen) are all fully built ✅.
No handover document has been received for the attendance history screen yet.

---

## 10. Admin Screens — Memberships, Payments, Settings, Notifications

**Source:** App scaffold
**Depends on:** Respective handover documents (not yet received)

**What they are:**
The following admin routes are currently `_PlaceholderScreen`:
- `/admin/memberships`
- `/admin/payments`
- `/admin/settings`
- `/admin/notifications`

Each will be implemented when its handover document is provided.

**Note:** `/admin/enrollment` is fully built ✅. `/admin/attendance` is fully built ✅.
`/admin/grading` is fully built ✅.

---

## 11. Memberships — PAYT Session Recording

**Source:** Attendance handover — PAYT stub
**Depends on:** Memberships feature

**What it is:**
When a student with a Pay-As-You-Train (PAYT) membership checks in to a session
(via self check-in, queue resolution, or coach marking), a `paytSessions` record
should be written to track billable sessions.

**Where stubs live:**
- `lib/domain/use_cases/attendance/self_check_in_use_case.dart` — `// TODO(memberships):` after `createRecord`
- `lib/domain/use_cases/attendance/create_attendance_session_use_case.dart` — `// TODO(memberships):` inside queue resolution loop
- `lib/domain/use_cases/attendance/mark_attendance_use_case.dart` — `// TODO(memberships):` inside upsert loop

**Logic to implement:**
1. Determine if the student's active membership for the discipline is PAYT
2. If yes, write a `paytSessions` document: `{studentId, sessionId, disciplineId, date, status: 'pending'}`
3. If a PAYT student is later unmarked by admin, cancel the pending `paytSessions` record
   (see note in `mark_attendance_use_case.dart` — currently a manual admin task)

---

## 12. Memberships — Lapsed Membership Flag on Dashboard

**Source:** Attendance handover
**Depends on:** Memberships feature, Dashboard feature

**What it is:**
When a student's membership is lapsed or expired and they check in (via self check-in),
an admin flag should appear on the dashboard to prompt follow-up.

**Where stubs live:**
- `lib/domain/use_cases/attendance/self_check_in_use_case.dart` — `// TODO(memberships):` comment

**Logic to implement:**
1. On self check-in, check if the student's membership for the discipline is lapsed/expired
2. If yes, write a `membershipFlags` document: `{studentId, disciplineId, sessionId, date, type: 'lapsed'}`
3. The admin dashboard should surface these flags for admin action

---

## 13. Grading — Membership Check During Nomination

**Source:** Grading feature implementation
**Depends on:** Memberships feature

**What it is:**
When an admin nominates a student for a grading event, the system should verify the student
has an active (non-lapsed, non-trial) membership for the discipline before allowing nomination.

**Where the stub lives:**
`lib/domain/use_cases/grading/nominate_student_use_case.dart`
```dart
// TODO(memberships): check student has an active membership for the discipline.
// Fetch the student's membership record for disciplineId; throw
// MembershipInactiveException if lapsed or not found.
```

**Logic to implement:**
1. Fetch the student's current membership for `disciplineId`
2. If not found or `status != active`: throw a descriptive exception
3. The `NominateStudentsScreen` already surfaces errors via SnackBar — no UI change needed
4. Admin should see a clear message if a nomination is blocked due to membership

---

## 14. Grading — Push Notifications

**Source:** Grading feature implementation
**Depends on:** Notifications / Firebase Cloud Messaging feature

**What it is:**
Two points in the grading flow currently write `NotificationLog` documents to Firestore
but do not send actual push notifications. When the notifications infrastructure is in place,
these stubs need to be wired up.

**Where the stubs live:**

1. **Nomination** — `lib/domain/use_cases/grading/nominate_student_use_case.dart`
```dart
// TODO(notifications): send push notification to student
// Type: gradingEligibility
// Recipient: studentId
// Payload: { gradingEventId, disciplineId, eventDate }
// The NotificationLog document is already written above.
```

2. **Promotion** — `lib/domain/use_cases/grading/record_grading_results_use_case.dart`
```dart
// TODO(notifications): send push notification to student
// Type: gradingPromotion
// Recipient: studentId
// Payload: { disciplineId, rankAchievedId, gradingScore, gradingDate }
// The NotificationLog document is already written above.
```

**Logic to implement:**
- Integrate with FCM (or equivalent) to send a push to the student's registered device token
- Device tokens should come from a `deviceTokens` subcollection on the profile (to be designed)
- The `NotificationLog` documents already record `sentAt` — update this after a successful send
