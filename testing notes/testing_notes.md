# Ichiban App — Testing Notes

Each section covers a feature or phase. Items marked ✅ are straightforward
happy-path checks. Items marked ⚠️ flag edge cases, known gaps, or things that
depend on a later phase being in place before they can be fully verified.

---

## Phase 0 — Project Scaffold

- [ ] ✅ App builds (flutter run) in both admin and student flavors without errors
- [ ] ✅ Firebase connects successfully (no Firestore permission errors on launch)
- [ ] ✅ Admin flavor opens to `/admin/login`
- [ ] ✅ Student flavor opens to `/student/select`

---

## Phase 1 — Data Layer (Entities, Repos, Converters, Seeder)

### Database Seeder

Run the seeder once against a fresh Firestore project and verify:

- [ ] ✅ `membershipPricing` collection contains 8 documents
- [ ] ✅ `appSettings` collection contains 8 keys:
      `lapseReminderPreDueDays`, `lapseReminderPostDueDays`,
      `trialExpiryReminderDays`, `dojoName`, `dojoEmail`,
      `privacyPolicyVersion`, `gdprRetentionMonths`, `financialRetentionYears`
- [ ] ✅ `emailTemplates` collection contains 4 documents
- [ ] ✅ `disciplines` collection contains 5 documents:
      Karate, Judo, Jujitsu, Aikido, Kendo
- [ ] ✅ Each discipline has a `ranks` subcollection
- [ ] ✅ Karate has 14 ranks (9 kyu + 5 dan)
- [ ] ✅ Judo has 29 ranks (18 mon + 6 kyu + 5 dan)
- [ ] ✅ Jujitsu has 19 ranks (14 kyu incl. tab variants + 5 dan)
- [ ] ✅ Aikido has 12 ranks (1 ungraded + 6 kyu + 5 dan)
- [ ] ✅ Kendo has 11 ranks (6 kyu + 5 dan)
- [ ] ✅ All Judo mon ranks have `monCount` set (0, 1, or 2)
- [ ] ✅ Jujitsu 7th Kyu and 6th Kyu variants have `monCount` 0–3
- [ ] ✅ Jujitsu 8th Kyu (white) has `monCount: null`
- [ ] ✅ Aikido ungraded rank has `rankType: "ungraded"` and colourHex `#FF0000`
- [ ] ✅ Kendo ranks have colourHex set (#FFFFFF kyu, #000000 dan)
- [ ] ⚠️ Seeder is idempotent — running it twice does NOT create duplicate documents
      (each collection checks `snap.docs.isNotEmpty` and skips if already seeded)

### Converters

- [ ] ✅ Round-trip test: create a `Profile` in Firestore via `ProfileConverter.toMap`,
      read it back via `ProfileConverter.fromMap` — all fields match including
      GDPR fields and nullable fields
- [ ] ✅ Same round-trip for `Discipline` and `Rank` (including `rankType` enum
      serialised as string name, `monCount` null vs int)
- [ ] ⚠️ `Timestamp` fields — verify `registrationDate`, `createdAt`, `dataProcessingConsentDate`,
      `anonymisedAt` survive the Firestore round-trip without timezone drift

---

## Phase 2 — Auth

### Admin login

- [ ] ✅ Valid Firebase email + password signs in and redirects to `/admin/dashboard`
- [ ] ✅ Wrong password shows error message in the form
- [ ] ✅ Empty email or password shows inline field errors (not a crash)
- [ ] ✅ "Forgot password" link sends a reset email (check Firebase Auth email logs)
- [ ] ✅ Signing out returns to `/admin/login`
- [ ] ⚠️ Direct navigation to `/admin/profiles` while signed out redirects to login

### Student PIN session

- [ ] ✅ Student select screen lists active profiles from Firestore
- [ ] ✅ Selecting a profile navigates to PIN entry
- [ ] ✅ Correct PIN authenticates and navigates to `/student/home`
- [ ] ✅ Wrong PIN shows error; does not navigate
- [ ] ✅ Back from PIN clears selection and returns to select screen
- [ ] ⚠️ Profile with no PIN set — verify PIN entry screen handles this gracefully
      (currently `pinHash` is nullable; behaviour on null hash not yet defined)

---

## Phase 1 (Repositories) — Firestore Implementations

- [ ] ✅ `FirestoreProfileRepository.create` returns a non-empty document ID
- [ ] ✅ `FirestoreProfileRepository.watchAll` emits updated list within ~1 s
      when a document is added or changed in Firestore console
- [ ] ✅ `FirestoreDisciplineRepository.watchAll` emits all disciplines
      (active and inactive)
- [ ] ✅ `FirestoreDisciplineRepository.watchActive` emits only active disciplines
- [ ] ✅ `FirestoreRankRepository.watchForDiscipline` emits ranks in
      `displayOrder` ascending order
- [ ] ✅ `FirestoreRankRepository.reorder` batch-writes correct `displayOrder`
      values (0-based index matching the supplied orderedRankIds list)

---

## Profile Use Cases

- [ ] ✅ `CreateProfileUseCase` throws `ArgumentError` if:
      - `firstName` is blank
      - `lastName` is blank
      - `profileTypes` is empty
      - `dataProcessingConsent` is false
- [ ] ✅ On success, returned ID matches the Firestore document
- [ ] ✅ `dataProcessingConsentDate` is stamped to `DateTime.now()` when not
      already set on the incoming profile
- [ ] ✅ `UpdateProfileUseCase` throws if name fields are blank
- [ ] ✅ `DeactivateProfileUseCase` sets `isActive: false` — profile no longer
      appears in `watchAll` filtered lists ⚠️ (only if list screens filter by isActive)
- [ ] ✅ `SetPinUseCase` — happy path sets a non-empty pinHash
- [ ] ✅ `SetPinUseCase` throws if PIN is empty or profileId is empty

---

## Profile Screens (Admin)

### Profile list screen (`/admin/profiles`)

- [ ] ✅ Shows all profiles from Firestore; updates live
- [ ] ✅ Search filters by full name (case-insensitive)
- [ ] ✅ Filter chips (All / Adult / Junior / Coach / Parent) narrow the list
- [ ] ✅ Inactive profiles show 'Inactive' badge
- [ ] ✅ Tapping a profile navigates to detail screen
- [ ] ✅ FAB navigates to create form

### Profile detail screen (`/admin/profiles/:id`)

- [ ] ✅ All fields display correctly including nullable fields
- [ ] ✅ Inactive profile shows red 'Inactive' banner
- [ ] ✅ Junior profile shows Family Links section
- [ ] ✅ Edit button opens edit form pre-populated with current values
- [ ] ✅ Deactivate button shows confirmation dialog; confirms deactivation;
      pops back to list
- [ ] ✅ Membership summary section shows active membership plan, status, renewal date, and a link to the full record
- [ ] ✅ Membership summary shows "No active membership" empty state when no active membership exists
- [ ] ✅ "Create" button in membership summary navigates to Create Membership wizard pre-selecting this profile
- [ ] ✅ "View" button in membership summary navigates to the membership detail screen

### Profile create / edit form (`/admin/profiles/create`, `/admin/profiles/:id/edit`)

- [ ] ✅ All required fields validated on save (red error text below empty fields)
- [ ] ✅ Date of birth picker works and shows selected date
- [ ] ✅ Profile type chips toggle correctly; at least one must be selected
- [ ] ✅ Photo/video consent switch works
- [ ] ✅ Family links section only appears when 'Junior Student' type is selected
- [ ] ✅ Save in create mode creates a new Firestore document and pops back
- [ ] ✅ Save in edit mode updates the existing document and pops back
- [ ] ✅ Error from use case is shown in a SnackBar (not a crash)
- [ ] ✅ GDPR consent checkbox is visible in create mode
- [ ] ✅ Save is blocked while consent checkbox is unchecked (inline error shown)
- [ ] ✅ Ticking the checkbox stamps the current `privacyPolicyVersion` from
      app settings as `dataProcessingConsentVersion` on the profile
- [ ] ✅ Unticking the checkbox clears the version
- [ ] ✅ Profile saves successfully once checkbox is ticked
- [ ] ✅ In edit mode with consent already given: green read-only banner shows
      with recorded policy version; no checkbox visible
- [ ] ✅ In edit mode with consent already given: banner text directs to
      erasure process (not the form) to withdraw consent
- [ ] ✅ Editing a profile no longer resets `registrationDate` or `isActive`
      (previously these were hardcoded in toProfile())

### Student profile screen (`/student/profile`)

- [ ] ✅ Read-only view of the active student's profile fields
- [ ] ✅ No edit controls visible

---

## Disciplines & Ranks Feature (Admin)

### Discipline list screen (`/admin/disciplines`)

- [ ] ✅ Shows all disciplines (active + inactive) streamed live
- [ ] ✅ Active disciplines sorted alphabetically before inactive ones
- [ ] ✅ Inactive disciplines display 'Inactive' badge and muted text
- [ ] ✅ Tapping a discipline navigates to the detail screen
- [ ] ✅ FAB navigates to the create form
- [ ] ✅ Empty state shows icon + prompt when no disciplines exist

### Discipline create form (`/admin/disciplines/create`)

- [ ] ✅ Name field required — shows error if blank
- [ ] ✅ Description field optional — can be left blank
- [ ] ✅ Saving creates a new Firestore document in `disciplines` collection
- [ ] ✅ Saved discipline appears in the list screen immediately (stream update)
- [ ] ✅ `createdAt` and `createdByAdminId` are set on the document
- [ ] ⚠️ `createdByAdminId` will be empty string if admin is somehow not
      authenticated (should not be reachable in normal flow due to router guard,
      but worth checking the Firestore document after save)

### Discipline edit form (`/admin/disciplines/:disciplineId/edit`)

- [ ] ✅ Form opens pre-populated with existing discipline values
- [ ] ✅ Name can be updated and saved
- [ ] ✅ Description can be updated, cleared (empty = stored as null in Firestore)
- [ ] ✅ Active toggle visible in edit mode only
- [ ] ✅ Toggling isActive off shows yellow warning banner about enrolments
- [ ] ✅ Saving with isActive = false marks discipline inactive in Firestore
- [ ] ✅ Inactive discipline immediately disappears from `activeDisciplineListProvider`
      but remains visible in `disciplineListProvider`

### Discipline detail screen (`/admin/disciplines/:disciplineId`)

- [ ] ✅ Shows discipline name, description, inactive banner if applicable
- [ ] ✅ Rank list loads in displayOrder order
- [ ] ✅ Each rank tile shows: colour swatch, name, RankType chip
- [ ] ✅ Rank with `monCount` set shows filled dot indicators
- [ ] ✅ Rank with `minAttendanceForGrading` set shows "N sessions min" label
- [ ] ✅ Rank with no colourHex shows grey swatch with reset icon
- [ ] ✅ Drag-to-reorder reorders the list and updates Firestore immediately
- [ ] ✅ After reorder, refreshing the screen shows the new order
- [ ] ✅ Popup menu on a rank: Edit navigates to rank edit form
- [ ] ✅ Popup menu on a rank: Delete shows confirmation dialog
- [ ] ✅ Confirmed delete removes the rank from Firestore and the list
- [ ] ✅ FAB navigates to rank create form, passing correct `nextDisplayOrder`
      (equal to current rank count)
- [ ] ✅ Edit button in AppBar navigates to discipline edit form
- [ ] ⚠️ Delete rank: the repo currently has NO guard checking whether any
      student holds this rank. Deletion will succeed even if the rank is in use.
      **A guard must be added before production use.**

### Rank create form (`/admin/disciplines/:disciplineId/ranks/create`)

- [ ] ✅ Name field required
- [ ] ✅ Rank type dropdown defaults to 'Kyu'
- [ ] ✅ Mon count field visible only when rank type = 'Mon / Tab'
- [ ] ✅ Switching away from 'Mon / Tab' clears the mon count field
- [ ] ✅ Hex colour field: only hex chars allowed (0–9, a–f), max 6 characters
- [ ] ✅ Live colour swatch updates as hex is typed
- [ ] ✅ Invalid hex length (< 6 chars) shows validation error on save
- [ ] ✅ Blank hex field accepted (no colour = null in Firestore)
- [ ] ✅ Min sessions field accepts positive integers only; blank = null
- [ ] ✅ Saving creates a new rank document in the correct discipline subcollection
- [ ] ✅ New rank appears at the bottom of the detail screen list

### Rank edit form (`/admin/disciplines/:disciplineId/ranks/:rankId/edit`)

- [ ] ✅ Form opens pre-populated with existing rank values
- [ ] ✅ All fields editable; saves correctly to Firestore
- [ ] ✅ Clearing the hex field saves `null` to Firestore (not empty string)
- [ ] ✅ Clearing mon count saves `null` to Firestore
- [ ] ✅ Clearing min sessions saves `null` to Firestore

---

---

## GDPR — Manual Right to Erasure (Profile Detail Screen)

### Erase Personal Data button

- [ ] ✅ 'Erase Personal Data' button visible on profile detail when `isAnonymised = false`
- [ ] ✅ Button NOT visible when profile is already anonymised
- [ ] ✅ Clicking button shows Step 1 dialog listing exactly what will be wiped
- [ ] ✅ Cancelling Step 1 dialog does nothing — profile unchanged
- [ ] ✅ Proceeding past Step 1 shows Step 2 'Final Confirmation' dialog
- [ ] ✅ Cancelling Step 2 does nothing — profile unchanged
- [ ] ✅ Confirming Step 2 triggers anonymisation

### After anonymisation

- [ ] ✅ Profile detail screen updates automatically (no manual refresh needed)
- [ ] ✅ Grey 'Personal data erased on [date]' banner appears at top
- [ ] ✅ First name, last name, date of birth, gender fields are hidden
- [ ] ✅ Contact section (phone, email, address) is hidden entirely
- [ ] ✅ Emergency contact section is hidden entirely
- [ ] ✅ Allergies / medical notes hidden
- [ ] ✅ Profile types and 'Member since' date still visible
- [ ] ✅ Photo/video consent row still visible
- [ ] ✅ 'Erase Personal Data' button no longer visible
- [ ] ✅ 'Deactivate Profile' button still visible if profile is still active
- [ ] ✅ Firestore document has `isAnonymised: true` and `anonymisedAt` timestamp
- [ ] ✅ Firestore document has `firstName: '[Anonymised]'`, `lastName: '[Anonymised]'` etc.
- [ ] ✅ Firestore document has `dateOfBirth` set to 1970-01-01 (epoch placeholder)
- [ ] ✅ Nullable fields (`gender`, `allergiesOrMedicalNotes`, `pinHash`, `fcmToken`) are null
- [ ] ⚠️ Profile list screen — anonymised profiles still appear in the list
      (they show '[Anonymised] [Anonymised]' as name). Confirm this is acceptable
      or add a filter/visual treatment with product owner.

### Use case guards

- [ ] ✅ `AnonymiseProfileUseCase` throws `StateError` if called on an already-anonymised profile
- [ ] ✅ `AnonymiseProfileUseCase` throws `ArgumentError` if profileId is empty

---

## Enrollment Feature

### Enrol Discipline Wizard (`/admin/profiles/:id/enrol`)

**Step 1 — Select Discipline**

- [ ] ✅ Launched from Profile Detail "Disciplines & Grading" tab → "Enrol in Discipline" button
- [ ] ✅ Active disciplines listed; already-enrolled (active) disciplines shown as disabled with a lock icon
- [ ] ✅ Disciplines with an inactive enrolment show a "Reactivate" badge
- [ ] ✅ Inactive disciplines shown with muted style and lock icon (not selectable)
- [ ] ✅ Tapping an active, not-yet-enrolled discipline advances to Step 2
- [ ] ✅ Tapping a "Reactivate" discipline skips Step 2 and goes directly to Step 3 confirmation

**Step 2 — Select Rank**

- [ ] ✅ All ranks for the selected discipline are displayed
- [ ] ✅ Default selection is the bottom rank (last in displayOrder)
- [ ] ✅ Tapping a rank card highlights it
- [ ] ✅ Back button returns to Step 1 with discipline selection cleared
- [ ] ✅ Continue advances to Step 3

**Step 3 — Confirm**

- [ ] ✅ Summary card shows discipline name, rank name, and belt colour swatch
- [ ] ✅ "Reactivating" label shown when reactivating an existing enrolment
- [ ] ✅ Confirm button triggers enrolment / reactivation and pops back to Profile Detail
- [ ] ✅ Profile Detail "Disciplines & Grading" tab updates immediately (stream)
- [ ] ⚠️ Student under age 5: red error banner appears at Step 3; Confirm button disabled
- [ ] ⚠️ Inactive discipline: use case throws even if tapped somehow — SnackBar error shown

### Use-case guards

- [ ] ✅ `EnrolStudentUseCase` throws `AgeRestrictionException` for students under 5
- [ ] ✅ `EnrolStudentUseCase` throws if discipline is inactive
- [ ] ✅ `EnrolStudentUseCase` throws if student already has an active enrolment for the discipline
- [ ] ✅ `ReactivateEnrollmentUseCase` finds the inactive record and sets `isActive: true` with a new `enrollmentDate`
- [ ] ✅ `DeactivateEnrollmentUseCase` sets the enrolment to inactive in Firestore

### Profile Detail — Disciplines & Grading tab

- [ ] ✅ Tab appears next to "Personal" tab; switching is smooth
- [ ] ✅ Active enrolments show: discipline name, belt colour swatch, rank name, enrolment date
- [ ] ✅ "Enrol in Discipline" button visible when no active enrolments (or always, to allow multi-discipline)
- [ ] ✅ Deactivate button on each active enrolment shows confirmation dialog; deactivates on confirm
- [ ] ✅ After deactivation, enrolment moves to the inactive section immediately (stream)
- [ ] ✅ Inactive enrolments appear in a collapsible "Inactive Enrolments" section
- [ ] ✅ Each inactive row has a "Reactivate" button that navigates to the enrol wizard at Step 3
- [ ] ⚠️ Profile with no enrolments shows appropriate empty state (not a blank tab)

### Discipline Detail — Enrolled Students section

- [ ] ✅ Enrolled students list appears below the rank ladder
- [ ] ✅ Each row shows student full name, current rank name, and belt swatch
- [ ] ✅ "Bulk Enrol via CSV" button present; taps navigate to bulk upload screen locked to this discipline
- [ ] ⚠️ Student name resolves correctly even for anonymised profiles (shows '[Anonymised] [Anonymised]')

### Bulk Enrolment — Upload screen (`/admin/enrollment` or from Discipline Detail)

- [ ] ✅ When launched from Discipline Detail: discipline chip shown locked; no dropdown
- [ ] ✅ When launched from global enrollment menu: discipline dropdown shown
- [ ] ✅ "Choose CSV File" button opens file picker (CSV only)
- [ ] ✅ Valid CSV with correct columns: row count shown, "Upload and Validate" enabled
- [ ] ✅ CSV with missing required column (firstName, lastName, dateOfBirth): error message shown, no row count
- [ ] ✅ Empty CSV file: "The CSV file is empty." error shown
- [ ] ✅ "Upload and Validate" button disabled while no file is loaded or while validating
- [ ] ✅ Loading spinner shown during validation
- [ ] ✅ On success, navigates to preview screen with parsed results

### Bulk Enrolment — CSV format

- [ ] ✅ DOB in wrong format (not DD/MM/YYYY) → error row in preview
- [ ] ✅ Student name + DOB not matching any profile → error row
- [ ] ✅ Discipline name not matching any active discipline (when not pre-locked) → error row
- [ ] ✅ Student already actively enrolled → skipped row
- [ ] ✅ Duplicate student+discipline row in same CSV → second row skipped
- [ ] ✅ Student with inactive enrolment → success row marked as reactivation
- [ ] ✅ Blank rank column → defaults to bottom rank of discipline (no error)
- [ ] ✅ Rank name not found in discipline → error row
- [ ] ✅ Student under age 5 → error row

### Bulk Enrolment — Preview screen

- [ ] ✅ Summary badge bar shows correct counts for to-enrol, skipped, errors
- [ ] ✅ "To Enrol" section lists each valid row with student name, discipline, rank
- [ ] ✅ Reactivation rows distinguished from new enrolment rows
- [ ] ✅ "Skipped" section collapsible; shows reason for each skip
- [ ] ✅ "Errors" section collapsible; shows row number, name, and reason for each error
- [ ] ✅ "Download Error Report" button visible when errors exist; generates and shares a CSV
- [ ] ✅ "Confirm Enrolments" disabled when no valid rows
- [ ] ✅ "Confirm Enrolments" commits all successes sequentially; shows SnackBar on completion
- [ ] ✅ After confirm: pops back through preview → upload → discipline detail (or enrollment list)
- [ ] ⚠️ If one enrolment fails mid-commit: error banner shown with count of successful records before failure; user can retry or manually correct

---

## Known Gaps / Deferred Items

These are not bugs — they are features not yet built. Flagged here to avoid
confusion during testing.

| Gap | Phase it belongs to |
|---|---|
| ~~`dataProcessingConsent` checkbox missing from profile create form~~ | ✅ Done |
| Anonymised profiles show '[Anonymised] [Anonymised]' in profile list — discuss with product owner | Profiles (visual treatment) |
| No guard on rank delete if students hold that rank | Grading feature |
| `minAttendanceForGrading` stored but not enforced anywhere | Grading feature |
| ~~Membership summary on profile detail is a placeholder~~ | ✅ Done |
| Student home and check-in screens are fully built ✅ | — |
| Student attendance history and grades screens are still placeholders | Student features |
| Dashboard is a placeholder | Dashboard feature |
| Settings, Notifications, Payments screens are placeholders | Respective features |
| PAYT session recording on check-in not yet built | Memberships / PAYT feature |
| Lapsed membership flag on dashboard not yet built | Dashboard feature |
| Membership auto-lapse / trial expiry Cloud Functions not built | Backend / Cloud Functions |
| Stripe payment integration not built | Payments / Stripe feature |
| PIN for profiles with no `pinHash` — behaviour undefined | Auth (next iteration) |
| GDPR anonymisation (Cloud Function) not built | Backend / Cloud Functions |
| GDPR data export (PDF/CSV) not built | GDPR feature |

---

## Attendance Feature

### Attendance List (`/admin/attendance`)

- [ ] ✅ Screen shows all sessions grouped by date, newest date first
- [ ] ✅ "Today" label shown in accent colour for today's group header
- [ ] ✅ Past dates shown in muted secondary colour
- [ ] ✅ Each session tile: discipline name, time range, live "N present" chip
- [ ] ✅ "Present" chip updates immediately when records stream in
- [ ] ✅ Filter dropdown lets admin show sessions for a single discipline
- [ ] ✅ Selecting "All Disciplines" (null) shows all sessions again
- [ ] ✅ When queued check-ins exist: badge with count appears in AppBar; tapping navigates to queued check-ins screen
- [ ] ✅ No badge shown when there are no pending queued check-ins
- [ ] ✅ FAB "Create Session" navigates to create session wizard
- [ ] ✅ Tapping a session tile navigates to session detail screen (session passed as `extra`)

### Create Session Wizard (`/admin/attendance/create`)

**Step 1 — Select Discipline**
- [ ] ✅ Only active disciplines listed
- [ ] ✅ Selecting a discipline advances to Step 2

**Step 2 — Select Date**
- [ ] ✅ Date picker has max date = today (future dates not selectable)
- [ ] ✅ "Next" button disabled until a date is picked
- [ ] ✅ Back button returns to Step 1

**Step 3 — Set Times**
- [ ] ✅ Start time and end time pickers work correctly
- [ ] ✅ Validation: end time must be after start time — error message shown
- [ ] ✅ Both fields required — error shown if either is empty
- [ ] ✅ Back button returns to Step 2

**Step 4 — Add Notes**
- [ ] ✅ Notes field is optional — tapping "Next" with empty field is allowed
- [ ] ✅ Notes field is multiline
- [ ] ✅ Back button returns to Step 3

**Step 5 — Confirm**
- [ ] ✅ Summary card shows discipline, date, time, and notes (if provided)
- [ ] ✅ Notes row hidden when notes is empty
- [ ] ✅ "Create Session" button triggers save
- [ ] ✅ On success: SnackBar "Session created." shown; wizard pops back to list
- [ ] ✅ On success with queued check-ins resolved: SnackBar says "Session created. N queued check-in(s) resolved."
- [ ] ⚠️ Queued check-in auto-resolution: only fires for today's date; creating a back-dated session does NOT resolve queued check-ins

### Session Detail (`/admin/attendance/:sessionId`)

- [ ] ✅ Header card shows date, time range, and notes (if any)
- [ ] ✅ All enrolled students for the discipline are listed with checkboxes
- [ ] ✅ Students who previously self-checked in appear pre-checked with "Self check-in" label
- [ ] ✅ Students marked by coach appear with "Coach marked" label
- [ ] ✅ Students not yet checked in appear unchecked (no subtitle)
- [ ] ✅ "All present" button checks all students
- [ ] ✅ "Clear all" button unchecks all students
- [ ] ✅ Summary bar shows "N / M present" count, updating as checkboxes change
- [ ] ✅ Toggling a checkbox marks the UI as dirty; FAB "Save Attendance" appears
- [ ] ✅ Save button in AppBar also appears when dirty
- [ ] ✅ On save: SnackBar "Attendance saved." shown; dirty state clears
- [ ] ✅ Saving correctly creates/deletes records in Firestore (opt-in model)
- [ ] ⚠️ Students enrolled AFTER the session was created will appear in the list but unchecked

### Queued Check-ins Screen (`/admin/attendance/queued`)

- [ ] ✅ Groups displayed by discipline + date; newest date first
- [ ] ✅ Each group header shows discipline name and formatted date
- [ ] ✅ Each queued check-in tile shows student name and queue time
- [ ] ✅ "Discard" (✕) icon on each tile; tapping discards the single check-in immediately (no confirm dialog)
- [ ] ✅ "Discard all" button per group shows a confirmation dialog
- [ ] ✅ Confirming "Discard all" discards all in the group and shows a SnackBar with count
- [ ] ✅ After all check-ins are discarded, the screen shows the empty state
- [ ] ✅ Empty state: "No pending check-ins" with a tick icon

### Student Home (`/student/home`)

- [ ] ✅ Student name shown in welcome card after PIN authentication
- [ ] ✅ "Check In to a Class" button navigates to self check-in flow
- [ ] ✅ "Sign out" button in AppBar clears the session and returns to student select screen

### Self Check-in Flow (`/student/checkin`)

**Step 1 — Select Discipline**
- [ ] ✅ Active disciplines listed; student sees all (not filtered by enrolment)
- [ ] ✅ Selecting a discipline advances to Step 2

**Step 2a — Session exists today**
- [ ] ✅ One or more sessions for the discipline shown as selectable cards
- [ ] ✅ Session card shows time range and notes (if any)
- [ ] ✅ Tapping a session triggers check-in

**Step 2b — No session today**
- [ ] ✅ "No session yet today" message shown with explanation
- [ ] ✅ "Join the Queue" button writes a queued check-in record
- [ ] ✅ "Cancel" button pops back to student home

**Check-in outcomes**
- [ ] ✅ Success: dialog "Checked in!" shown; tapping Done returns to student home
- [ ] ✅ Already checked in: error message shown inline (no navigation)
- [ ] ✅ Queued: dialog with queue message shown; tapping Done returns to student home
- [ ] ✅ Already queued: dialog with "Already queued" message shown
- [ ] ✅ Auto-enrolled: success dialog notes "automatically enrolled and checked in"
- [ ] ⚠️ AgeRestrictionException (auto-enrol fail): "please speak to a coach" error shown inline
- [ ] ⚠️ No ranks on discipline (auto-enrol fail): StateError message shown inline

### Profile Detail — Attendance History section

- [ ] ✅ "Attendance History" section card appears in Disciplines & Grading tab
- [ ] ✅ Loading state shows a spinner inside the card
- [ ] ✅ When no records: "No attendance records yet." shown
- [ ] ✅ Records grouped by discipline; disciplines sorted alphabetically
- [ ] ✅ Each discipline shows total sessions attended count
- [ ] ✅ Tapping discipline group expands to show individual session rows
- [ ] ✅ Each row: check-in method icon (phone/coach), formatted date, method label
- [ ] ✅ Sessions within a discipline sorted newest first
- [ ] ⚠️ Attendance history is loaded as a one-time `FutureProvider` (not a live stream) — a page refresh is needed to see newly added records while the screen is open

### Firestore data integrity

- [ ] ✅ `attendanceSessions` documents contain: `disciplineId`, `sessionDate` (midnight UTC), `startTime`, `endTime`, `notes`, `createdByAdminId`, `createdAt`
- [ ] ✅ `attendanceRecords` documents contain: `sessionId`, `studentId`, `disciplineId`, `sessionDate`, `checkInMethod`, `checkedInByProfileId`, `timestamp`
- [ ] ✅ `queuedCheckIns` documents contain: `studentId`, `disciplineId`, `queueDate` (midnight UTC), `queuedAt`, `status`
- [ ] ✅ Resolved `queuedCheckIns` have `resolvedSessionId` and `resolvedAt` set
- [ ] ✅ Discarded `queuedCheckIns` have `discardedByAdminId` and `discardedAt` set

---

## Grading Feature

### Grading Event List (`/admin/grading`)

- [ ] ✅ Screen shows all grading events when no discipline filter is active
- [ ] ✅ Status filter chips (All / Upcoming / Completed / Cancelled) filter the list correctly
- [ ] ✅ Selecting a filter chip highlights it and updates the list immediately
- [ ] ✅ "All" chip is selected by default
- [ ] ✅ Empty state with icon shown when no events match the selected filter
- [ ] ✅ Each event tile shows: event title (or discipline name), discipline name, date, status badge
- [ ] ✅ Tapping a tile navigates to the event detail screen
- [ ] ✅ FAB "New Event" navigates to create grading event screen
- [ ] ✅ When navigated from Discipline Detail's grading section, list is pre-filtered to that discipline
- [ ] ✅ When navigated from an enrollment row's "Grading" shortcut, list is pre-filtered to that discipline

### Create Grading Event (`/admin/grading/create`)

- [ ] ✅ Discipline dropdown shows only active disciplines
- [ ] ✅ When navigated from a discipline shortcut, that discipline is pre-selected in the dropdown
- [ ] ✅ Date field defaults to today; tapping opens the date picker
- [ ] ✅ Title and Notes fields are optional — event saves without them
- [ ] ✅ Tapping "Create Event" with no discipline selected shows validation error
- [ ] ✅ Valid form creates the event and navigates back to the grading list
- [ ] ✅ New event appears in the list with status "Upcoming"
- [ ] ✅ Save button shows a spinner while saving and is disabled to prevent double-submit

### Grading Event Detail (`/admin/grading/:eventId`)

- [ ] ✅ Event date and status badge shown in the info card
- [ ] ✅ Notes shown below the date when present; not shown when null
- [ ] ✅ Students section shows nominated student count in the header
- [ ] ✅ Empty state ("No students nominated yet") shown when no students are nominated
- [ ] ✅ Each student tile shows the student's full name
- [ ] ✅ Student tile shows grading score (if set) below the name
- [ ] ✅ Student tile shows outcome badge once a result is recorded
- [ ] ✅ Student tile shows "Record result" link (with chevron) when no result and event is upcoming
- [ ] ✅ Student tile shows "Pending" when event is completed but no outcome was recorded
- [ ] ✅ Tapping a student tile with no result navigates to Record Results screen
- [ ] ✅ FAB "Nominate Students" is shown when event status is Upcoming
- [ ] ✅ FAB is hidden when event is Completed or Cancelled
- [ ] ✅ PopupMenu (⋮) is shown when status is Upcoming; hidden otherwise
- [ ] ✅ "Mark as Complete" shows a confirmation dialog; confirming changes status to Completed
- [ ] ✅ "Cancel Event" shows a destructive confirmation dialog; confirming changes status to Cancelled
- [ ] ✅ After marking complete or cancelling, screen pops and list reflects new status

### Nominate Students (`/admin/grading/:eventId/nominate`)

- [ ] ✅ Shows only students actively enrolled in the event's discipline
- [ ] ✅ Students already nominated for this event are excluded from the list
- [ ] ✅ Shows both adult and junior student profiles by name
- [ ] ✅ Falls back to displaying `studentId` if profile has not loaded yet
- [ ] ✅ Empty state ("All enrolled students have already been nominated") shown when no eligible students remain
- [ ] ✅ Selecting students enables the "Nominate (N)" button in the AppBar
- [ ] ✅ "Nominate (N)" button shows a spinner while saving and is disabled during save
- [ ] ✅ Nominates all selected students and pops back to event detail
- [ ] ✅ Newly nominated students appear in the event detail student list immediately
- [ ] ✅ A SnackBar confirms how many students were nominated (with correct singular/plural)

### Record Results (`/admin/grading/:eventId/record-results`)

- [ ] ✅ Student name shown in the info card at the top
- [ ] ✅ Event title (or "Grading Event") shown below the student name in the info card
- [ ] ✅ Outcome selector shows three segments: Promoted / Not promoted / Absent
- [ ] ✅ No segment is selected by default
- [ ] ✅ Tapping a segment selects it; tapping again does not deselect (selection is required)
- [ ] ✅ "Rank Achieved" section appears only when "Promoted" is selected
- [ ] ✅ "Rank Achieved" section is hidden when outcome is changed away from Promoted
- [ ] ✅ Rank dropdown shows only ranks with a higher displayOrder than the student's current rank
- [ ] ✅ "Grading Score" section appears only when Promoted AND the discipline has `hasGradingScore = true`
- [ ] ✅ Score field accepts decimals; rejects non-numeric input
- [ ] ✅ Score outside 0–100 range shows a validation error and does not save
- [ ] ✅ Notes field is optional; saves correctly when empty
- [ ] ✅ Tapping "Save Result" with no outcome selected shows an error
- [ ] ✅ Tapping "Save Result" with Promoted selected but no rank shows an error
- [ ] ✅ Valid result saves and pops back; a SnackBar confirms "Result recorded."
- [ ] ✅ Save button shows a spinner while saving and is disabled during save
- [ ] ⚠️ When outcome is Promoted, a `gradingRecords` document is created in Firestore
- [ ] ⚠️ When outcome is Promoted, the student's `currentRankId` on their enrollment is updated
- [ ] ⚠️ When outcome is Failed or Absent, no `gradingRecords` document is written — only the `gradingEventStudent` outcome field is updated

### Profile Detail — Grading History section

- [ ] ✅ "Grading History" section card appears in Disciplines & Grading tab for admin view
- [ ] ✅ Records are grouped by discipline
- [ ] ✅ Each discipline group shows an ExpansionTile with the record count
- [ ] ✅ Expanding shows individual rows: rank name, date, and score (if set)
- [ ] ✅ Empty state ("No grading history.") shown when student has no records
- [ ] ✅ "Grading" shortcut button on active enrollment row navigates to grading list pre-filtered to that discipline
- [ ] ⚠️ Grading history shows only `promoted` outcomes — failed and absent outcomes are not listed (by design, they are recorded on `gradingEventStudent` only)

### Discipline Detail — Grading Events section

- [ ] ✅ "Grading Events" section card appears below the rank list in the discipline detail screen
- [ ] ✅ Upcoming events listed under "Upcoming" heading; past events under "Past"
- [ ] ✅ Each event row shows the event title (or discipline name) and formatted date
- [ ] ✅ Tapping an event row navigates to the event detail screen
- [ ] ✅ "View all" button navigates to grading list pre-filtered to this discipline
- [ ] ✅ Empty state ("No grading events yet") shown when no events exist for this discipline

### Student Grades (`/student/grades`)

- [ ] ✅ Screen accessible via "My Grades" button on StudentHomeScreen
- [ ] ✅ Shows a card for each active enrollment (one per discipline)
- [ ] ✅ Each card shows the discipline name and current rank name
- [ ] ✅ Belt icon uses the rank's `colourHex` (coloured border + tinted background)
- [ ] ✅ "Unknown rank" shown when the current rank cannot be matched
- [ ] ✅ Empty state ("You are not enrolled in any disciplines yet") shown when no active enrollments
- [ ] ✅ Each card includes a promotion history section below the header
- [ ] ✅ Promotion history collapses to an ExpansionTile when more than 3 records
- [ ] ✅ Promotion history is expanded by default when ≤ 3 records
- [ ] ✅ Each promotion row shows: up-arrow icon, rank name, grading score (if set), date
- [ ] ✅ "No promotions yet." shown when no grading records exist for the discipline

### Firestore data integrity

- [ ] ✅ `gradingEvents` documents contain: `disciplineId`, `status`, `eventDate`, `title` (nullable), `notes` (nullable), `createdByAdminId`, `createdAt`
- [ ] ✅ Completed `gradingEvents` have `status: "completed"`
- [ ] ✅ Cancelled `gradingEvents` have `status: "cancelled"`, `cancelledByAdminId`, `cancelledAt`
- [ ] ✅ `gradingEventStudents` documents contain: `gradingEventId`, `studentId`, `disciplineId`, `enrollmentId`, `currentRankId`, `nominatedByAdminId`, `nominatedAt`
- [ ] ✅ `gradingEventStudents` with a recorded outcome have: `outcome`, `resultRecordedByAdminId`, `resultRecordedAt`
- [ ] ✅ Promoted `gradingEventStudents` have `rankAchievedId` set
- [ ] ✅ `gradingEventStudents` with a grading score have `gradingScore` set (numeric, 0–100)
- [ ] ✅ `gradingRecords` documents are only created for `promoted` outcomes
- [ ] ✅ `gradingRecords` contain: `studentId`, `disciplineId`, `enrollmentId`, `gradingEventId`, `fromRankId`, `rankAchievedId`, `outcome: "promoted"`, `gradingDate`, `markedEligibleByAdminId`, `gradedByAdminId`
- [ ] ✅ `gradingRecords` contain `gradingScore` (nullable) and `notes` (nullable)
- [ ] ✅ A promoted student's `currentRankId` on their `enrollments` document is updated to the new rank
- [ ] ⚠️ `notificationLog` documents are written for nomination (type: `gradingEligibility`) and promotion (type: `gradingPromotion`) — actual push delivery is not yet implemented (see Deferred features item 14)

---

## Memberships Feature

### Membership List (`/admin/memberships`)

- [ ] ✅ Shows all memberships from Firestore; updates live
- [ ] ✅ Status filter chips (All / Trial / Active / Lapsed / Cancelled / Expired / PAYT) narrow the list
- [ ] ✅ Search by member name (primary holder or any family member) is case-insensitive
- [ ] ✅ Each tile shows: primary holder name, plan badge, status badge, amount, and renewal date
- [ ] ✅ Family memberships show member names below the primary holder name
- [ ] ✅ PAYT memberships show "PAYT" instead of a renewal date
- [ ] ✅ FAB "Create Membership" navigates to the create wizard
- [ ] ✅ Tapping a tile navigates to membership detail screen

### Create Membership Wizard (`/admin/memberships/create`)

**Step 1 — Plan Type**

- [ ] ✅ All 8 plan types displayed as selectable cards
- [ ] ✅ Selected plan card shows accent border and check icon
- [ ] ✅ Selecting a plan advances to Step 2
- [ ] ⚠️ Trial and PAYT plans skip the payment step (progress bar still shows 4 steps correctly)

**Step 2 — Assign Members**

- [ ] ✅ For non-family plans: single member search; selecting a profile assigns them as primary holder
- [ ] ✅ For family plans: multi-select search; first selected becomes primary holder; subsequent become members
- [ ] ✅ Family tier indicator updates as members are added (Up to 3 / 4+ tier)
- [ ] ✅ Primary holder can be changed by removing and re-adding members
- [ ] ✅ When launched from Profile Detail with `preselectedProfileId`, that profile is pre-selected and locked
- [ ] ✅ Search filters by full name (case-insensitive, all profile types)
- [ ] ✅ Continue button disabled until at least one member is assigned

**Step 3 — Payment Method**

- [ ] ✅ Shown for monthly/annual/family plans (Cash, Card, Bank Transfer options)
- [ ] ✅ Skipped entirely for Trial and PAYT plans (wizard jumps from Step 2 to Step 4)
- [ ] ✅ Selected payment method shows accent border and check icon
- [ ] ✅ Default selection is Cash

**Step 4 — Review & Confirm**

- [ ] ✅ Shows plan label, member(s), payment method (or "N/A" for trial/PAYT), and amount from live pricing
- [ ] ✅ Amount shown with correct frequency (/month, /year)
- [ ] ✅ Family tier shown for family plans
- [ ] ✅ "Create Membership" button triggers save; spinner shown while saving
- [ ] ✅ On success: SnackBar "Membership created." shown; wizard pops back
- [ ] ✅ Error from use case (e.g. member already has active membership) shown in SnackBar

### Active Membership Guard

- [ ] ⚠️ Attempting to create a membership for a member who already has an active membership throws an error
- [ ] ⚠️ The error message names the conflicting member ("… already has an active membership")
- [ ] ⚠️ For family plans, each individual member is checked; error fires on the first conflict

### Membership Detail (`/admin/memberships/:membershipId`)

**Plan summary section**

- [ ] ✅ Plan label, status badge, amount (with frequency), and renewal date shown
- [ ] ✅ Trial memberships show trial expiry date instead of renewal date
- [ ] ✅ PAYT memberships show "Pay As You Train" with no renewal date
- [ ] ✅ Cancelled memberships show cancelled date and "Cancelled by [admin]" (or "System")

**Members section (family memberships)**

- [ ] ✅ Primary holder highlighted separately from other members
- [ ] ✅ "Add Member" button appears for family memberships
- [ ] ✅ Adding a member: search dialog, select profile, member added to Firestore and list updates
- [ ] ✅ Remove button on each non-primary member; shows confirmation dialog before removing
- [ ] ✅ Family tier label shown (Up to 3 / 4+ members); tier note explains tier changes only at renewal
- [ ] ⚠️ Removing the primary holder is blocked — SnackBar error shown

**Payment history section**

- [ ] ✅ Shows all `cashPayments` records linked to this membership
- [ ] ✅ Each row: amount, payment method badge, date recorded
- [ ] ✅ Payment method badge shows Cash / Card / Bank Transfer
- [ ] ✅ Empty state shown when no payment records

**Membership history section**

- [ ] ✅ Shows all `membershipHistory` records ordered newest first
- [ ] ✅ Each row: change type icon, change type label, date, "by [admin name or System]"
- [ ] ✅ Previous → new plan shown for plan changes
- [ ] ✅ Notes shown when present on a history record

**Actions (PopupMenuButton)**

- [ ] ✅ "Renew" navigates to Renew Membership screen; disabled for PAYT, Trial, Cancelled, Expired
- [ ] ✅ "Convert Plan" navigates to Convert Membership Plan screen; disabled for PAYT, Trial, Cancelled
- [ ] ✅ "Manual Status Override" opens dialog with status dropdown and required notes field
- [ ] ✅ "Cancel Membership" shows confirmation dialog with optional notes field
- [ ] ✅ After cancellation: status updates to Cancelled; history record written; screen updates live

### Renew Membership (`/admin/memberships/:membershipId/renew`)

- [ ] ✅ Step 1 shows current plan label, new renewal date (extended from current renewal date, not today), and new amount from live pricing
- [ ] ✅ Price change callout shown when the new price differs from the stored amount
- [ ] ✅ Step 2: payment method selection (Cash / Card / Bank Transfer)
- [ ] ✅ Step 3: confirmation summary with new renewal date and payment method
- [ ] ✅ "Confirm Renewal" saves; SnackBar "Membership renewed." shown; pops back to detail
- [ ] ✅ Family tier is recalculated at renewal time (tier based on current member count at time of renewal)
- [ ] ✅ Annual plans extend by 1 year; monthly plans extend by 1 month

### Convert Membership Plan (`/admin/memberships/:membershipId/convert`)

- [ ] ✅ Step 1 shows all plan types; current plan is highlighted and non-selectable
- [ ] ✅ Selecting a new plan shows the new amount from live pricing
- [ ] ✅ Step 2: payment method (hidden for Trial/PAYT targets)
- [ ] ✅ Step 3: confirmation summary
- [ ] ✅ On confirm: old membership is cancelled, new membership created for same primary holder
- [ ] ✅ Wizard double-pops on success (returns to membership list, not the stale detail)
- [ ] ⚠️ Active membership guard is bypassed for conversion because the old membership is cancelled first

### Manual Status Override

- [ ] ✅ Status dropdown shows all status values except the current one
- [ ] ✅ Notes field is required — "Save" button disabled until notes are non-empty
- [ ] ✅ Saving updates `status` and `isActive` on the Firestore document
- [ ] ✅ History record written with `changeType: statusOverride` and the provided notes
- [ ] ✅ Membership detail updates live after override

### Grading nomination guard

- [ ] ⚠️ Nominating a student with no active membership throws a descriptive error — SnackBar shown on NominateStudentsScreen
- [ ] ⚠️ Nominating a student with a trial membership is blocked (trial is not considered "active" for grading purposes)
- [ ] ⚠️ Nominating a student with a lapsed membership is blocked

### Firestore data integrity

- [ ] ✅ `memberships` documents contain: `planType`, `status`, `isActive`, `primaryHolderId`, `memberProfileIds`, `monthlyAmount`, `paymentMethod`, `familyPricingTier` (family only), `createdByAdminId`, `createdAt`
- [ ] ✅ Monthly/annual memberships have `subscriptionRenewalDate` set
- [ ] ✅ Trial memberships have `trialStartDate` and `trialExpiryDate` set; no `subscriptionRenewalDate`
- [ ] ✅ PAYT memberships have `status: "payt"` and `isActive: true`; no renewal or trial dates
- [ ] ✅ Cancelled memberships have `cancelledAt`, `cancelledByAdminId` (nullable if system-cancelled)
- [ ] ✅ `membershipHistory` subcollection records contain: `membershipId`, `changeType`, `previousStatus`, `newStatus`, `changedByAdminId` (nullable), `triggeredByCloudFunction`, `changedAt`
- [ ] ✅ `membershipHistory` records for plan changes contain `previousPlanType` and `newPlanType`
- [ ] ✅ `membershipHistory` records for renewals contain `previousAmount`, `newAmount`
- [ ] ✅ `cashPayments` records for memberships contain `membershipId`, `amount`, `paymentMethod`, `recordedByAdminId`, `recordedAt`
- [ ] ✅ `cashPayments` records have `paytSessionId: null` when linked to a membership (and vice versa — `membershipId: null` for PAYT session payments)
- [ ] ⚠️ No `cashPayment` is written for Trial or PAYT memberships at creation time
- [ ] ⚠️ `stripeCustomerId` and `stripeSubscriptionId` are null placeholders — Stripe integration not yet built

---

## Phase 8 — Payments

### Data model

- [ ] ✅ `paytSessions` documents contain: `profileId`, `disciplineId`, `sessionDate`, `attendanceRecordId` (nullable), `paymentMethod`, `paymentStatus`, `paidAt` (nullable), `amount`, `recordedByAdminId` (nullable), `writtenOffByAdminId` (nullable), `writtenOffAt` (nullable), `writeOffReason` (nullable), `createdAt`, `notes` (nullable)
- [ ] ✅ `cashPayments` documents now include `paymentType` (`membership` | `payt` | `other`) and `editedByAdminId` / `editedAt` (both nullable, set on edit)
- [ ] ✅ Legacy `cashPayments` documents that predate `paymentType` are gracefully handled — inferred as `membership` if `membershipId` is set, else `payt`
- [ ] ✅ `cashPayments` documents now include `paymentMethod` for all records (legacy records default to `cash`)

### PAYT auto-creation (attendance integration)

- [ ] ✅ Self check-in by a PAYT student creates a pending `paytSessions` record with `amount` from `membership.monthlyAmount`
- [ ] ✅ Coach marking a PAYT student present creates a pending `paytSessions` record
- [ ] ✅ Queue resolution for a PAYT student (on session creation) creates a pending `paytSessions` record
- [ ] ✅ `paytSessions` record is linked to the attendance record (`attendanceRecordId`) immediately on creation
- [ ] ⚠️ If a PAYT student is unmarked by a coach, their pending `paytSessions` record is NOT automatically cancelled — admin must action manually (documented in code comment)
- [ ] ⚠️ Non-PAYT students do NOT get a `paytSessions` record on check-in

### Profile → Payments tab

- [ ] ✅ Profile detail screen has a third "Payments" tab
- [ ] ✅ Tab shows a combined list of `CashPayments` + `PaytSessions` sorted by date descending
- [ ] ✅ Outstanding balance banner appears for PAYT members with pending sessions, shows count + total
- [ ] ✅ Each entry shows: date, type, method, amount, status badge (Paid / Pending / Written off)
- [ ] ✅ Notes / write-off reason shown if present

### Payments list screen (`/admin/payments`)

- [ ] ✅ Lists all `CashPayments` with member name, date, type, method, amount
- [ ] ✅ Filter chips: All | Membership | PAYT | Other — correctly filter the list
- [ ] ✅ FAB navigates to Record Payment screen
- [ ] ⚠️ Financial Report button (bar chart icon) is only visible to super admins (currently always hidden — `isSuperAdminProvider` returns `false`)
- [ ] ✅ Tapping a row navigates to Payment Detail screen

### Payment Detail screen

- [ ] ✅ Shows all audit fields: member, type, method, recorded at, recorded by, linked IDs, notes
- [ ] ✅ Edit history section (Edited by / Edited at) only appears if the record has been edited
- [ ] ⚠️ Edit button only visible to super admins (currently always hidden)
- [ ] ⚠️ Edit sheet validates amount > 0; save calls `EditPaymentUseCase`; screen pops on success

### Resolve PAYT session (single)

- [ ] ✅ `ResolvePaytSessionUseCase` marks session paid + writes `CashPayment` with `paymentType: payt`
- [ ] ✅ `WriteOffPaytSessionUseCase` marks session writtenOff + sets `paymentMethod: writtenOff`; no `CashPayment` is written for write-offs

### Bulk resolve screen (`/admin/payments/bulk-resolve/:profileId`)

- [ ] ✅ Lists all pending sessions for the profile with checkboxes
- [ ] ✅ Select-all checkbox selects/deselects all
- [ ] ✅ Resolve panel shows count + total and payment method dropdown
- [ ] ✅ "Mark N as Paid" button is disabled while busy; shows spinner during operation
- [ ] ✅ On success, screen pops with snack bar confirmation
- [ ] ⚠️ Admin ID hardcoded as `'admin'` — update when auth session is built

### Record standalone payment (`/admin/payments/record`)

- [ ] ✅ Dropdown lists all active members (active first, alphabetical)
- [ ] ✅ Amount validates > 0
- [ ] ✅ Payment method: Cash | Card | Bank Transfer
- [ ] ✅ Creates `CashPayment` with `paymentType: other`, no linked membership or PAYT session
- [ ] ⚠️ Admin ID hardcoded as `'admin'` — update when auth session is built
- [ ] ⚠️ Pre-selected profile (from `extra`) is applied post-frame — visible after first render

### Financial Report screen (`/admin/payments/report`)

- [ ] ⚠️ Only reachable by super admins (currently unreachable — `isSuperAdminProvider` returns `false`)
- [ ] ✅ Shows total collected + outstanding PAYT balance
- [ ] ✅ Breakdown by payment type and by payment method
- [ ] ✅ Export CSV includes: all `CashPayments` + pending `PaytSessions`; CSV is shared via `share_plus`

### Router

- [ ] ✅ `/admin/payments` → `PaymentsListScreen`
- [ ] ✅ `/admin/payments/record` → `RecordPaymentScreen`
- [ ] ✅ `/admin/payments/report` → `FinancialReportScreen`
- [ ] ✅ `/admin/payments/bulk-resolve/:profileId` → `BulkResolveScreen`
- [ ] ✅ `/admin/payments/:paymentId` → `PaymentDetailScreen` (requires `CashPayment` in `extra`)
