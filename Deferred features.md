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

## 0. TESTING CLEANUP — Delete temporary admin Firestore document

**Source:** Testing session 2026-05-01
**Priority:** Must do before any real data or production use

**What it is:**
A temporary `adminUsers` document was manually created in Firestore to bypass the setup
wizard during testing. It must be deleted before running the setup wizard properly.

**Document to delete:**
- Collection: `adminUsers`
- Document ID: `E88rIjsab7h5ixUtjcQUSj45hB53`
- Email: `kieronhg@yahoo.com`

**How to delete:**
Option A — Firebase Console: Firestore → `adminUsers` collection → select the document → Delete.
Option B — Firebase CLI: `npx firebase-tools firestore:delete --project ichiban-app adminUsers/E88rIjsab7h5ixUtjcQUSj45hB53 --yes`

**Also delete the corresponding Firebase Auth user** (`E88rIjsab7h5ixUtjcQUSj45hB53`) from
Firebase Console → Authentication, then re-run the setup wizard from Settings to create the
owner account properly with the full wizard flow (dojo name, disciplines, etc.).

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



## 16. Memberships — Stripe Cloud Functions (Backend Only)

**Source:** Memberships handover + Payments/Invites/Notifications handover (2026-05-02)
**Depends on:** Memberships feature ✅, Stripe account setup, Firebase Blaze plan
**Scope:** Backend Cloud Functions ONLY — Flutter UI is complete

**Flutter UI already built (session 2026-05-02):**
- `StripeService` in `lib/core/services/stripe_service.dart` — wraps all callable function calls
- `StudentPortalMembershipScreen` — plan selection sheet, upgrade/downgrade/cancel flows,
  grace period warning banner, pending downgrade notice
- `MembershipStatus.gracePeriod` — enum value + all switch expressions updated
- `Membership` entity — `gracePeriodEnd`, `pendingDowngradePlanId`, `downgradeRequestedAt` fields
- Repository methods: `cancelAtPeriodEnd`, `startGracePeriod`, `requestDowngrade`, `clearPendingDowngrade`

**Cloud Functions still needed (`functions/` TypeScript directory):**

### `createStripeCustomer` (HTTP Callable)
- Input: `{ profileId: string }`
- Creates a Stripe customer with the profile's email
- Saves `stripeCustomerId` to the Firestore membership document
- Returns: `{ customerId: string }`

### `createStripeSubscription` (HTTP Callable)
- Input: `{ profileId: string, planKey: string }`
- Calls `ensureCustomer` internally, then creates a Stripe subscription for the plan price ID
- Returns a `paymentIntent.client_secret` for the Flutter payment sheet
- On success: writes membership with `status: active`, `stripeSubscriptionId`, `subscriptionRenewalDate`
- Returns: `{ clientSecret: string }`

### `upgradeStripeSubscription` (HTTP Callable)
- Input: `{ profileId: string, newPlanKey: string }`
- If upgrading: immediately swaps to new price ID via `subscription.update()`
- If downgrading: stores `pendingDowngradePlanId` on Firestore (applied at period end by webhook)
- Returns: `{ clientSecret: string? }` — null for downgrades (no immediate charge)

### `cancelStripeSubscription` (HTTP Callable)
- Input: `{ profileId: string }`
- Calls `stripe.subscriptions.update(id, { cancel_at_period_end: true })`
- Updates Firestore: `cancelledAt: now` (leaves `isActive: true` until period ends)

### `onStripeWebhook` (HTTP trigger, not callable)
- Verifies Stripe webhook signature
- Handles:
  - `invoice.paid` → set `status: active`, update `subscriptionRenewalDate`, apply pending downgrade if any, write payment history record
  - `invoice.payment_failed` → call `startGracePeriod` (7-day window), send `paymentFailed` notification
  - `customer.subscription.deleted` → set `status: lapsed`, `isActive: false`, send `membershipLapsed` notification

### `onGracePeriodExpired` (scheduled — runs daily)
- Find all memberships where `status == gracePeriod` AND `gracePeriodEnd < now`
- Set `status: lapsed`, `isActive: false`
- Send `membershipLapsed` notification to member

**Stripe plan key → price ID mapping:**
Plan keys: `basicMonthly`, `basicAnnual`, `familyMonthly`, `familyAnnual` (plus `studentTrial` — no Stripe price, trial only).
Store the mapping in Firebase Remote Config or a Firestore `config/stripePrices` document.

---

## 22. Notifications — Membership Firestore Triggers

**Source:** Notifications & Emails handover
**Depends on:** Notifications Flutter layer ✅ (now built), Firebase Blaze plan for email
**Scope:** Backend only — `functions/` TypeScript directory

**What it is:**
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

---

## 27. Invites — Cloud Functions (Backend Only)

**Source:** Payments/Invites/Notifications handover (2026-05-02)
**Depends on:** Admin invite Flutter UI ✅ (now built)
**Scope:** Backend Cloud Functions ONLY — Flutter UI is complete

**Flutter already built:**
- `AcceptInviteScreen` — deep-link landing, password + PIN setup, creates Firebase Auth user
- `InviteExpiredScreen` — expired link handling, request resend button
- `_InviteSection` on `ProfileDetailScreen` — send/resend invite button, status badge
- `profile.inviteStatus`, `inviteSentAt`, `inviteExpiresAt`, `inviteResendCount` fields on Profile

**Cloud Functions needed:**

### `sendStudentInviteEmail` (HTTP Callable)
- Input: `{ profileId: string }`
- Reads the profile to get email and first name
- Generates the deep link: `https://app.ichibanapp.com/invite/accept?profileId=<id>`
  (or the Firebase Dynamic Links equivalent if using dynamic links)
- Sends an email from the email template (`emailTemplates/studentInvite` document)
- **Requires Blaze plan** for outbound email

### `requestInviteResend` (HTTP Callable)
- Input: `{ profileId: string }`
- Increments `inviteResendCount` on the profile
- Resets `inviteExpiresAt` to 24 hours from now
- Sets `inviteStatus: pending`
- Notifies admin (writes a notification log of type `newSelfRegistration` or a new admin-targeted type)
- Returns `{ success: true }`

### `onInviteExpired` (scheduled — runs hourly or daily)
- Finds all profiles where `inviteStatus == pending` AND `inviteExpiresAt < now`
- Sets `inviteStatus: expired` on each
- Sends `inviteExpired` notification to the admin (if notification type is wired up)

---

## 28. Notifications — Cloud Functions (Backend Only)

**Source:** Payments/Invites/Notifications handover (2026-05-02)
**Depends on:** Notifications Flutter layer ✅ (built in prior session)
**Scope:** Backend Cloud Functions ONLY

**Cloud Functions needed:**

### `sendAnnouncement` (HTTP Callable)
- Input: `{ title: string, body: string, targetType?: string }`
- Looks up all profiles with a stored `fcmToken` (optionally filtered by `profileType`)
- Sends an FCM multicast message
- Writes a `notificationLog` document for each recipient
- Type: `generalDojoAnnouncement`

### `onTrialExpirySoon` (scheduled — runs daily)
- Finds all memberships where `planType == studentTrial` AND `trialExpiryDate` is within
  the alert window (default 7 days, from `appSettings.trialExpiryAlertDays`)
- Sends a `trialExpiring` push notification to each member
- Respects `communicationPreferences.trialExpiryReminders`

### `cleanupExpiredNotifications` (scheduled — runs daily)
- Deletes `notificationLogs` documents older than `appSettings.notificationRetentionDays`
- This is the automatic counterpart to the manual `clearNotificationLogs` callable (item 25)

**FCM token storage:**
The `fcmToken` field on `Profile` is already defined. The Flutter app must call
`FirebaseMessaging.instance.getToken()` on login and save it to the profile via
`profileRepository.update(profile.copyWith(fcmToken: token))`. This is not yet wired up —
add it to `student_auth_provider.dart` or the student portal init flow.

---

## 29. Members list — Discipline filter chip

**Source:** admin-members.html design handoff
**Depends on:** A bulk enrollment provider or denormalised discipline field on Profile

**What it is:**
The "Discipline · Any" chip in the Members list filter bar is shown but non-functional.
It should filter the list to only show members enrolled in a specific discipline.

**Why deferred:**
Getting each member's enrolled discipline requires per-profile enrollment stream lookups
(`allEnrollmentsForStudentProvider(profileId)`). Running one stream per member in a list
of 140+ is expensive. The right fix is a new aggregated provider or a denormalised
`primaryDisciplineId` field on the `Profile` entity.

**Implementation options:**
A) Add `primaryDisciplineId: String?` to the `Profile` entity and populate it on
   enrolment — cheapest for the list screen.
B) Create a new `allEnrollmentsProvider` (StreamProvider) that subscribes to the
   `enrollments` collection group query in Firestore, builds a `Map<studentId, List<Enrollment>>`,
   and exposes it. The list screen uses the map for filtering without per-row streams.

**Flutter file:** `lib/presentation/features/profiles/profile_list_screen.dart`
— Look for the `_IchibanChip('Discipline · Any', ...)` chip with empty `onTap: () {}`.

---

## 30. Members list — Export CSV

**Source:** admin-members.html design handoff

**What it is:**
The "Export CSV" button in the Members list AppBar is present but does nothing (`onPressed: () {}`).
It should export the current filtered list as a CSV file and share/download it.

**Columns to include:** Name, Age, Join Date, Discipline, Rank, Role, Status, Email, Phone.

**Implementation:**
- Use the `csv` package (not yet in pubspec.yaml) to build the CSV string
- Filter to the currently visible members (respecting active type/status/search filters)
- Use `share_plus` or `path_provider` to save/share the file
- Consider adding a loading state while generating

**Flutter file:** `lib/presentation/features/profiles/profile_list_screen.dart`
— Look for `OutlinedButton(onPressed: () {}, ...)` in the AppBar actions.
