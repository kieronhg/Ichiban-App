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


## 22. Notifications — Membership Firestore Triggers

**Source:** Notifications & Emails handover
**Depends on:** Notifications Flutter layer ✅ (now built), Firebase Blaze plan for email
**Scope:** Backend only — `functions/` TypeScript directory

**What's already built ✅:**
- `onGradingEligibilityCreated`, `onGradingPromotionRecorded` — grading push triggers ✅
- `onCoachComplianceUpdated` — compliance submitted/verified push triggers ✅
- `sendAnnouncement` — HTTP callable for announcements ✅
- `dailyLapseCheck`, `dailyTrialExpiryCheck` — scheduled membership status updates ✅
- `dailyDbsExpiryCheck`, `dailyFirstAidExpiryCheck` — scheduled compliance expiry alerts ✅
- `cleanStaleFcmTokens` — scheduled FCM token cleanup ✅

**What still needs building:**
Three Firestore triggers to push notifications when membership status changes:

1. `onMembershipLapsed` — fires when `membership.status` changes to `lapsed`
   → send lapse reminder push (and email on Blaze) to member
   → type: `lapseReminderPost`

2. `onMembershipExpiringSoon` — fires when `membership.subscriptionRenewalDate` enters alert window
   → send pre-lapse reminder push (and email on Blaze) to member
   → type: `lapseReminderPre`

3. `onTrialExpiringSoon` — fires when `membership.trialExpiryDate` enters alert window
   → send trial expiry push (and email on Blaze) to member
   → type: `trialExpiring`

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

---

## 24. Settings — `bulkAnonymise` Cloud Function (HTTP Callable)

**Source:** Settings handover — Part 7 / Part 13
**Depends on:** Settings Flutter UI ✅ (now built)
**Scope:** Backend / Firebase Cloud Functions — NOT Flutter

**What it is:**
An HTTP callable Cloud Function that anonymises all eligible profiles in one batch.
The Settings GDPR screen Flutter UI already calls `FirebaseFunctions.instance.httpsCallable('bulkAnonymise')`.
The function must return `{ count: int }`.

**Eligibility logic:**
- `profiles` where `isActive = false` (or lapsed/expired/cancelled membership) AND `isAnonymised = false`
- Membership lapse/cancellation date > `appSettings/gdprRetentionMonths` months ago

**Fields to wipe per profile:**
`firstName`, `lastName`, `dateOfBirth`, `addressLine1`, `addressLine2`, `city`, `county`,
`postcode`, `country`, `phone`, `email`, `emergencyContactName`, `emergencyContactRelationship`,
`emergencyContactPhone`, `allergiesOrMedicalNotes`, `gender`, `pinHash`, `fcmToken`

**Profile updates:** `isAnonymised: true`, `anonymisedAt: now`

**Flutter file:** `lib/domain/use_cases/settings/trigger_bulk_anonymise_use_case.dart`

---

## 25. Settings — `clearNotificationLogs` Cloud Function (HTTP Callable)

**Source:** Settings handover — Part 11 / Part 13
**Depends on:** Settings Flutter UI ✅ (now built)
**Scope:** Backend / Firebase Cloud Functions — NOT Flutter

**What it is:**
An HTTP callable Cloud Function that deletes `notificationLogs` documents where
`sentAt < today - olderThanDays`. Called from the Danger Zone settings screen.

**Parameters received:** `{ olderThanDays: int }`
**Return value:** `{ count: int }` — number of deleted records

**Flutter file:** `lib/domain/use_cases/settings/clear_notification_logs_use_case.dart`

---

## 26. Settings — Bulk Data Export Cloud Function

**Source:** Settings handover — Part 7
**Depends on:** All feature collections (memberships, payments, grading, attendance, enrollment)
**Scope:** Backend Cloud Function + delivery mechanism

**What it is:**
A Cloud Function that generates a full export of all non-anonymised member records
in CSV and/or PDF format, then delivers the file(s) to the owner.

**Includes:** Profiles, memberships, enrollments, grading records, attendance records, payment records.

**Format options:** CSV / PDF / Both — selected by owner in the GDPR Settings screen.

**Delivery:** Cloud Function generates file(s) and either:
- Returns a download URL (Firebase Storage), or
- Emails the export to the dojo email address

**Flutter side:** The GDPR settings screen (`lib/presentation/features/settings/gdpr_settings_screen.dart`)
already shows the export UI. Currently shows a "not yet available" snackbar when tapped.
When the function is deployed, replace the snackbar with the actual callable.
