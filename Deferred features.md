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

## 4. Discipline Inactivity Enforcement

**Source:** Disciplines, Ranks & GDPR handover — Section 3
**Depends on:** Enrollment feature, Attendance feature, Grading feature

**What it is:**
When a discipline has `isActive: false`, the following must be blocked:
- No new student enrolments into the discipline
- No new attendance sessions created for the discipline
- No new grading events triggered for the discipline

**What is already built:**
- `isActive` flag exists on `Discipline` entity ✅
- `activeDisciplineListProvider` streams only active disciplines ✅
- The deactivation toggle + warning banner exists in `DisciplineFormScreen` ✅

**What still needs enforcing:**
Each relevant feature must filter its discipline dropdown / creation flow to only
show `activeDisciplineListProvider` (active disciplines). The data layer guard should
also be added at the use-case level (e.g. `CreateEnrolmentUseCase` should check
`discipline.isActive` before persisting).

Admin can still **view** inactive disciplines and their enrolled students for
historical reference — this is already supported via `disciplineListProvider`.

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

## 9. Student App Screens (Home, Attendance, Grades)

**Source:** App scaffold
**Depends on:** Enrollment, Attendance, Grading features

**What they are:**
The following student routes are currently `_PlaceholderScreen`:
- `/student/home` — student dashboard
- `/student/attendance` — student's own attendance history
- `/student/grades` — student's current rank and grading history

No handover documents have been received for these screens yet.

---

## 10. Admin Screens — Enrollment, Attendance, Grading, Memberships, Payments, Settings, Notifications

**Source:** App scaffold
**Depends on:** Respective handover documents (not yet received)

**What they are:**
The following admin routes are currently `_PlaceholderScreen`:
- `/admin/enrollment`
- `/admin/attendance`
- `/admin/grading`
- `/admin/memberships`
- `/admin/payments`
- `/admin/settings`
- `/admin/notifications`

Each will be implemented when its handover document is provided.
The data layer (entities, repository interfaces, Firestore implementations) for
enrollment, grading, attendance, membership, payments, and notifications is already
built — only the use cases and UI remain.
