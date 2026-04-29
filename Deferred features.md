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

## 10. Admin Screen — Settings

**Source:** App scaffold
**Depends on:** Settings handover document (not yet received)

**What it is:**
`/admin/settings` is currently a `_PlaceholderScreen`. Will be implemented when its handover document is provided.

---

## 14. Grading — Push Notifications (Cloud Functions)

**Source:** Grading feature implementation
**Depends on:** Notifications Cloud Functions (item 22)

**What it is:**
The grading flow writes Firestore documents that Cloud Functions must react to in order
to send push notifications. The Flutter-side TODO stubs have been removed — Flutter now
owns only the business data write; Cloud Functions own notification delivery.

**Cloud Function triggers needed (part of item 22):**

1. **onGradingEligibilityStudentCreated** — fires when a `gradingEventStudents` document is written
   with `isNominated = true`. Sends push to the student:
   - Type: `gradingEligibility`, recipient: student profileId
   - Payload: `{ gradingEventId, disciplineId, eventDate }`
   - Writes a `notificationLogs` document

2. **onGradingPromotionRecorded** — fires when a `gradingEventStudents` document is updated
   with `outcome = promoted`. Sends push to the student:
   - Type: `gradingPromotion`, recipient: student profileId
   - Payload: `{ disciplineId, rankAchievedId, gradingScore, gradingDate }`
   - Writes a `notificationLogs` document

---

## 15. Memberships — Automatic Lapse & Trial Expiry (Cloud Functions)

**Source:** Memberships handover
**Depends on:** Memberships feature ✅ (now built)
**Scope:** Backend / Firebase Cloud Functions — NOT Flutter

**What it is:**
Two scheduled Cloud Functions that run daily to keep membership statuses current without
requiring admin action:

1. **Lapse function** — finds all `active` memberships where `subscriptionRenewalDate < today`
   and updates their `status` to `lapsed`, sets `isActive = false`, and writes a `membershipHistory`
   record with `changeType: lapsed`.

2. **Trial expiry function** — finds all `trial` memberships where `trialExpiryDate < today`
   and updates their `status` to `expired`, sets `isActive = false`, and writes a `membershipHistory`
   record with `changeType: cancelled` (or a new `expired` change type if added).

**Firestore fields available:**
- `subscriptionRenewalDate` (Timestamp) on all non-trial, non-PAYT memberships
- `trialExpiryDate` (Timestamp) on trial memberships
- `status` (String — enum name)
- `isActive` (bool)
- `membershipHistory` subcollection (via `FirestoreMembershipHistoryRepository`)

**Note:** The Flutter app reads `status` and `isActive` as set by these functions. No Flutter
change is needed — lapsed/expired memberships will automatically surface correctly in all
existing screens once the functions run.

---

## 16. Memberships — Stripe Payment Integration

**Source:** Memberships handover
**Depends on:** Memberships feature ✅ (now built), Stripe account setup
**Scope:** Backend Cloud Functions + Flutter (partial)

**What it is:**
The `Membership` entity has `stripeCustomerId` and `stripeSubscriptionId` placeholder fields
already stored on the Firestore document. When Stripe integration is built:

1. **Backend:** Cloud Functions handle Stripe webhooks (`invoice.paid`, `invoice.payment_failed`,
   `customer.subscription.deleted`) and update Firestore membership status accordingly.

2. **Flutter:** `PaymentMethod.stripe` is already a valid enum value. The Create wizard's
   payment step should show a Stripe option that launches the Stripe payment sheet (using
   `flutter_stripe` package — not yet in `pubspec.yaml`).

3. **Renewal:** Stripe subscriptions auto-renew; the Cloud Function webhook updates
   `subscriptionRenewalDate` and writes a `membershipHistory` record after each successful charge.

**Note:** `CashPayment` records are NOT written for Stripe payments — the Stripe webhook
handles the payment record side. The `paymentMethod: stripe` guard in `CreateMembershipUseCase`
already skips the cash payment write.

---

## 18. Coach Compliance — DBS & First Aid Expiry Cloud Functions

**Source:** Coach Profiles handover — Part 7
**Depends on:** Coach Profiles feature ✅ (now built)
**Scope:** Backend / Firebase Cloud Functions — NOT Flutter

**What they are:**
Two scheduled Cloud Functions running daily:

1. **DBS Expiry Check** — queries all `coachProfiles` where `dbs.expiryDate` is within
   `appSettings/dbsExpiryAlertDays` (default 60) days of today OR already past.
   - If already past → set `dbs.status = "expired"` on the document
   - Push notification to the coach: "Your DBS check expires on [date]. Please renew it."
   - Push notification to all owners: "[Coach Name]'s DBS check expires on [date]."
   - Write `notificationLogs` record for each alert

2. **First Aid Expiry Check** — same pattern for `firstAid.expiryDate`.
   - Push notification to the coach: "Your First Aid certification expires on [date]."
   - Push notification to all owners: "[Coach Name]'s First Aid certification expires on [date]."

**Alert threshold** is read from `appSettings/dbsExpiryAlertDays` and
`appSettings/firstAidExpiryAlertDays` (both default 60). Owner can update
these values in the Settings screen (when built).

**Note:** The Flutter app already displays `dbs.status = expired` correctly
(shown in red with `_DbsStatusBadge`). The Cloud Function only needs to
write the status update and fire notifications.

---

## 19. Coach Compliance — Push Notifications (Stubs)

**Source:** Coach Profiles handover — Part 13
**Depends on:** Notifications / Firebase Cloud Messaging feature

**What it is:**
Three notification types introduced by the Coach Profiles feature. The use
cases already contain TODO stubs. When notifications infrastructure is built,
wire these up:

1. **Coach submits DBS update** — `lib/domain/use_cases/coach/coach_update_dbs_use_case.dart`
   ```
   TODO(notifications): send push notification to all owners after save.
   Type: coachComplianceSubmitted, payload: { adminUserId, complianceType: dbs }
   ```

2. **Coach submits first aid update** — `lib/domain/use_cases/coach/coach_update_first_aid_use_case.dart`
   ```
   TODO(notifications): send push notification to all owners after save.
   Type: coachComplianceSubmitted, payload: { adminUserId, complianceType: firstAid }
   ```

3. **Owner verifies compliance** — `lib/domain/use_cases/coach/verify_coach_compliance_use_case.dart`
   ```
   TODO(notifications): send push notification to the coach after save.
   Type: coachComplianceVerified, payload: { adminUserId, complianceType, verifiedByName }
   ```

---

## 21. Coach Compliance — Settings Screen Controls

**Source:** Coach Profiles handover — Part 7 / Part 13
**Depends on:** Settings feature (item 10, not yet built)

**What it is:**
Two configurable `appSettings` documents:
- `dbsExpiryAlertDays` — days before DBS expiry to fire alert (default 60)
- `firstAidExpiryAlertDays` — days before first aid expiry to fire alert (default 60)

Owner can edit these values in the Settings screen. The Cloud Functions (item 18)
read these values at runtime.

---

## 22. Notifications — Firebase Cloud Functions (13 functions)

**Source:** Notifications & Emails handover
**Depends on:** Notifications Flutter layer ✅ (now built), Firebase Blaze plan for email
**Scope:** Backend only — `functions/` TypeScript directory

**What it is:**
All notification delivery logic lives in Cloud Functions. Flutter only writes business data;
Cloud Functions react via Firestore triggers and scheduled jobs.

**Functions to build:**

### Firestore triggers
1. `onMembershipLapsed` — fires when `membership.status` changes to `lapsed`
   → send lapse reminder push (and email on Blaze) to member
   → type: `lapseReminderPost`

2. `onMembershipExpiringSoon` — fires when `membership.subscriptionRenewalDate` enters alert window
   → send pre-lapse reminder push (and email on Blaze) to member
   → type: `lapseReminderPre`

3. `onTrialExpiringSoon` — fires when `membership.trialExpiryDate` enters alert window
   → send trial expiry push (and email on Blaze) to member
   → type: `trialExpiring`

4. `onGradingEligibilityStudentCreated` — fires when `gradingEventStudents` doc written with `isNominated = true`
   → push to student: grading eligibility
   → type: `gradingEligibility`

5. `onGradingPromotionRecorded` — fires when `gradingEventStudents` doc updated with `outcome = promoted`
   → push to student: grading promotion
   → type: `gradingPromotion`

6. `onCoachComplianceSubmitted` — fires when `coachProfiles.dbs` or `.firstAid` is updated
   → push to all owners: compliance review needed
   → type: `complianceSubmitted`

7. `onCoachComplianceVerified` — fires when `coachProfiles.dbs.status` or `.firstAid.status` set to `verified`
   → push to coach: compliance verified
   → type: `complianceVerified`

### HTTP callable
8. `sendAnnouncement(title, body, channel, audience, disciplineId?)` — called by `SendAnnouncementUseCase`
   → resolves recipient FCM tokens (all members or discipline members)
   → sends push via FCM admin SDK
   → email on Blaze plan only (gate with env var `EMAIL_ENABLED`)
   → writes `announcements` document and `notificationLogs` for each recipient

### Scheduled (daily)
9. `dailyLapseCheck` — mark memberships lapsed, send lapseReminderPre/Post
10. `dailyTrialExpiryCheck` — mark trials expired, send trialExpiring
11. `dailyDbsExpiryCheck` — update DBS status, send dbsExpiry alerts
12. `dailyFirstAidExpiryCheck` — update first aid status, send firstAidExpiry alerts
13. `cleanStaleFcmTokens` — remove FCM tokens older than 30 days (stale device cleanup)

### FCM token pattern
- Member FCM tokens: stored at `profiles/{profileId}.fcmToken` + `fcmTokenUpdatedAt`
- Admin FCM tokens: stored at `adminUsers/{uid}.fcmToken` + `fcmTokenUpdatedAt`
- Flutter writes these via `FcmService` (already built); Cloud Functions read them at send time

### Email gating
Email delivery requires Firebase Blaze plan (external network calls). Gate with:
```typescript
if (process.env.EMAIL_ENABLED === 'true') { /* send via Nodemailer */ }
```
Upgrade Blaze plan, then set `EMAIL_ENABLED=true` in Functions config to activate.

---

## 23. Notifications — Email Delivery (Blaze Plan Required)

**Source:** Notifications & Emails handover, session decision 2026-04-27
**Depends on:** Firebase Blaze plan upgrade, Cloud Functions (item 22)

**What it is:**
Email notifications via Nodemailer require outbound network calls from Cloud Functions,
which are only available on the Firebase Blaze (pay-as-you-go) plan. The app is currently
on the Spark (free) plan.

**Push notifications work on Spark** — FCM is a Google service, so no external network call
is needed. All push-only flows are fully functional now.

**When upgrading to Blaze:**
1. Upgrade the Firebase project to Blaze in the Firebase Console
2. Deploy Cloud Functions (item 22) with `EMAIL_ENABLED=true` in environment config
3. Configure Nodemailer SMTP credentials in Functions secrets
4. Test all email template types end-to-end

**Templates already exist in Firestore:** `emailTemplates` collection with 4 documents (seeded).
Admin can edit them via the Email Template screens (already built).
