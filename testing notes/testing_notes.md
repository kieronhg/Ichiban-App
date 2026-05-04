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

---

## Sessions C–E — Auth, Coach Management, Role Guards

### PIN lockout (`pin_entry_screen.dart`)

- [ ] ✅ Entering wrong PIN 5 times locks out for 5 minutes
- [ ] ✅ Countdown timer displays MM:SS and ticks down every second
- [ ] ✅ Numpad is hidden while locked — tapping locked screen does nothing
- [ ] ✅ After lockout expires, attempts reset and numpad reappears automatically
- [ ] ✅ Warning "1 attempt remaining" shown after 4th wrong PIN
- [ ] ✅ No-PIN banner shown when `profile.pinHash == null`; numpad hidden
- [ ] ⚠️ Lockout state is in-memory — restarting the app resets the counter

### Session timeout (`student_home_screen.dart`)

- [ ] ✅ Tapping/swiping student home screen stamps activity and resets idle timer
- [ ] ✅ After 5 minutes of no interaction, student is signed out and redirected to student select
- [ ] ⚠️ Timeout check runs every 30s — maximum actual idle before signout is 5m 30s

### Coach management

#### Team List (`/admin/team`)
- [ ] ✅ Lists all admin users sorted owners-first then alpha by last name
- [ ] ✅ Owner badge shown in amber; Coach badge shown in blue
- [ ] ✅ Deactivated users shown with strikethrough name and grey avatar
- [ ] ✅ "Invite Coach" FAB only visible when current user is owner
- [ ] ✅ Tapping a row navigates to team detail

#### Invite Coach (`/admin/team/invite`)
- [ ] ✅ Requires first name, last name, email, temporary password (≥ 8 chars)
- [ ] ✅ Password show/hide toggle works
- [ ] ✅ At least one discipline must be checked before submitting
- [ ] ✅ Warning shown if no active disciplines exist
- [ ] ✅ Creating account does NOT sign out the current admin (secondary Firebase app)
- [ ] ✅ On success: snackbar shown, returns to team list; new coach appears in list
- [ ] ✅ Duplicate email shows friendly Firebase error message
- [ ] ⚠️ Coach receives no automated welcome email — must be given credentials manually

#### Team Detail (`/admin/team/:uid`)
- [ ] ✅ Shows profile card, role badge, status badge, email, last login, disciplines
- [ ] ✅ Edit button only visible to owners; navigates to edit screen
- [ ] ✅ Owner cannot perform actions on themselves (no action section visible)
- [ ] ✅ Deactivate → confirmation dialog → coach status becomes "Deactivated"
- [ ] ✅ Reactivate → confirmation → coach status becomes "Active"
- [ ] ✅ Promote to Owner → confirmation → role badge changes to Owner
- [ ] ✅ Demote to Coach → discipline-select bottom sheet → must pick ≥ 1 discipline → role changes to Coach
- [ ] ✅ Delete → double-confirmation → coach removed from list; navigates back
- [ ] ⚠️ Deleting a coach does NOT remove their Firebase Auth account — must be done manually in Firebase Console

#### Edit Coach / Admin (`/admin/team/:uid/edit`)
- [ ] ✅ Pre-fills first name, last name, email from existing record
- [ ] ✅ Coach discipline checkboxes pre-checked with current assignments
- [ ] ✅ Coach must remain assigned to ≥ 1 discipline on save
- [ ] ✅ Owner edit form does not show discipline section
- [ ] ✅ Save shows success snackbar and navigates back

### PIN Reset

- [ ] ✅ "Reset PIN" button visible on profile detail Personal tab when `pinHash != null`
- [ ] ✅ Confirmation dialog mentions student will be unable to sign in until new PIN assigned
- [ ] ✅ After reset: `pinHash` cleared in Firestore; student sees no-PIN banner at next lock screen
- [ ] ✅ Button not shown for anonymised profiles

### Role Guards (coaches)

#### Attendance list
- [ ] ✅ Coach's discipline dropdown initialises to their first assigned discipline (not "All")
- [ ] ✅ "All Disciplines" option absent from dropdown for coaches
- [ ] ✅ Dropdown only shows disciplines the coach is assigned to

#### Create Attendance Session — Step 1 (Select Discipline)
- [ ] ✅ Coaches only see their assigned active disciplines in the list
- [ ] ✅ Owners see all active disciplines

#### Grading Events list
- [ ] ✅ Coaches with 1 assigned discipline: no dropdown shown; events auto-filtered to that discipline
- [ ] ✅ Coaches with 2+ disciplines: dropdown shown with their disciplines only; no "All" option
- [ ] ✅ Owners see full discipline filter including "All Disciplines"

#### Create Grading Event — Discipline dropdown
- [ ] ✅ Coaches only see their assigned active disciplines
- [ ] ✅ Owners see all active disciplines

---

## Coach Profiles

### Coach creation — coachProfiles document

- [ ] ✅ Inviting a new coach (via Invite Coach screen) creates both an `adminUsers` document AND a `coachProfiles` document
- [ ] ✅ New `coachProfiles` document has `dbs.status = notSubmitted`, both `pendingVerification = false`
- [ ] ✅ Demoting an owner to coach does NOT create a duplicate `coachProfiles` document if one already exists

### Coach login redirect

- [ ] ✅ A coach who logs in is redirected to `/admin/my-profile`, not `/admin/dashboard`
- [ ] ✅ An owner who logs in is redirected to `/admin/dashboard`
- [ ] ✅ A coach who manually navigates to `/admin/dashboard` is redirected to `/admin/my-profile`
- [ ] ✅ An owner who manually navigates to `/admin/my-profile` is redirected to `/admin/dashboard`

### My Profile screen (`/admin/my-profile`)

- [ ] ✅ Shows coach's full name, email (read-only), assigned disciplines (read-only)
- [ ] ✅ Shows qualifications notes if set; nothing shown if empty
- [ ] ✅ DBS card shows correct status badge (Not Submitted / Pending / Clear / Expired)
- [ ] ✅ Certificate number is masked by default (shows last 4 digits); tapping Show reveals full number
- [ ] ✅ Issue date and expiry date display correctly
- [ ] ✅ Expiry within 60 days: days-until-expiry shown in amber
- [ ] ✅ Expiry already passed: days-since-expiry shown in red
- [ ] ✅ Pending verification badge shows when `dbs.pendingVerification = true`
- [ ] ✅ First Aid card shows same patterns as DBS
- [ ] ✅ Upcoming Sessions card shows next 5 sessions for assigned disciplines; shows "No upcoming sessions" if none
- [ ] ✅ Upcoming Gradings card shows next 3 grading events for assigned disciplines; shows "No upcoming grading events" if none
- [ ] ✅ "View all" links on sessions/gradings cards navigate correctly
- [ ] ✅ Screen is not accessible to owners

### Edit Personal Details (`/admin/my-profile/edit`)

- [ ] ✅ Form pre-populated with current first name, last name, qualifications
- [ ] ✅ First name and last name are required; saving with either blank shows validation error
- [ ] ✅ Saving updates `adminUsers` (name) and `coachProfiles` (qualifications)
- [ ] ✅ No owner notification sent; no pending verification badge set
- [ ] ✅ Success snackbar shown; screen pops after save

### Update DBS Details (`/admin/my-profile/dbs`)

- [ ] ✅ Form pre-populated with current DBS data
- [ ] ✅ Status dropdown shows all four values
- [ ] ✅ Date pickers work correctly for issue and expiry dates
- [ ] ✅ Saving updates `coachProfiles.dbs` immediately
- [ ] ✅ `pendingVerification` set to `true` after coach save
- [ ] ✅ `submittedByCoachAt` set to current time
- [ ] ✅ Warning banner shown before saving explaining owner will be notified
- [ ] ✅ Success snackbar confirms owner notified; screen pops
- [ ] ⚠️ Push notification to owners is a TODO stub — not sent yet (depends on notifications feature)

### Update First Aid Details (`/admin/my-profile/firstaid`)

- [ ] ✅ Same pattern as DBS update — all fields, pending verification, stub notification

### Owner — Coach Detail Screen compliance section (`/admin/team/:uid`)

- [ ] ✅ Compliance section only visible to owners, only for coaches (not shown for owner-role users)
- [ ] ✅ DBS card shows status badge, full certificate number (unmasked), dates
- [ ] ✅ First Aid card shows certification name, issuing body, dates
- [ ] ✅ Expiry colour coding applies (amber ≤60 days, red = expired)
- [ ] ✅ Pending verification banner shown when `pendingVerification = true`
- [ ] ✅ "Verify" button clears `pendingVerification`, sets `lastUpdatedByAdminId` and `lastUpdatedAt`
- [ ] ✅ After verify, pending banner disappears
- [ ] ⚠️ Push notification to coach on verify is a TODO stub — not sent yet

### Owner — Edit Compliance (`/admin/team/:uid/compliance/edit`)

- [ ] ✅ DBS edit: status dropdown, certificate number, issue date, expiry date all editable
- [ ] ✅ First aid edit: certification name, issuing body, issue date, expiry date all editable
- [ ] ✅ Saving sets `pendingVerification = false` (owner edit counts as verified)
- [ ] ✅ `lastUpdatedByAdminId` and `lastUpdatedAt` recorded on save
- [ ] ✅ No notification sent for owner-initiated edits
- [ ] ✅ Success snackbar; screen pops back to coach detail

### Student Home — Coach display

- [ ] ✅ Student enrolled in a discipline with an assigned coach sees "Discipline: Coach Name" below the welcome message
- [ ] ✅ Multiple coaches for the same discipline shown as comma-separated names
- [ ] ✅ Discipline with no assigned coach: row not shown (no "Discipline: " with empty value)
- [ ] ✅ Student enrolled in multiple disciplines: each discipline shows its own coach row
- [ ] ✅ Student with no active enrollments: no coach rows shown

### Access control

- [ ] ✅ Coach cannot navigate to another coach's My Profile URL (no such screen — each coach only sees their own)
- [ ] ✅ Compliance section on Admin User Detail Screen not rendered for non-owner sessions
- [ ] ✅ Owner compliance edit screen not accessible by coaches (router redirect via role guard)

---

## Notifications & Emails Feature

> ⚠️ **Email delivery requires Firebase Blaze plan.** All email-channel tests below can only
> be verified after upgrading to Blaze and setting `EMAIL_ENABLED=true` in Cloud Functions
> environment config. Push-only tests can be run on the Spark plan.

### FCM token capture

- [ ] ✅ After admin login, `adminUsers/{uid}.fcmToken` is written to Firestore
- [ ] ✅ After student PIN entry, `profiles/{profileId}.fcmToken` is written to Firestore
- [ ] ✅ After sign-out (admin or student), token is NOT cleared from Firestore (Cloud Function cleans stale tokens daily)
- [ ] ✅ `fcmTokenUpdatedAt` timestamp is updated alongside the token

### Admin notification list

- [ ] ✅ `/admin/notifications` shows a list of all notification log entries from Firestore
- [ ] ✅ Filter sheet: selecting a type / channel / status and tapping Apply re-fetches with filters applied
- [ ] ✅ Tapping Clear in filter sheet restores all results
- [ ] ✅ Pull-to-refresh re-fetches the list
- [ ] ✅ Empty state shown when no logs exist
- [ ] ✅ Delivery status badge shows correct colour: green (sent), red (failed), grey (suppressed)

### Admin notification detail

- [ ] ✅ Tapping a notification log opens the detail screen
- [ ] ✅ All populated fields are shown: title, body, channel, type, recipient type, recipient ID, sent at
- [ ] ✅ `readAt` row shown only when present
- [ ] ✅ Failure / suppression section shown only when either field is present
- [ ] ✅ Announcement section shown only when `announcementId` is present
- [ ] ✅ Status card shows correct icon and colour

### Send Announcement (push only — Spark plan)

- [ ] ✅ Tapping the send icon on the notification list screen opens `SendAnnouncementScreen`
- [ ] ✅ Step 1: Next button disabled until title and body are non-empty
- [ ] ✅ Step 2: Audience — All members can be selected; discipline dropdown appears when "Specific discipline" is selected
- [ ] ✅ Step 3: Channel options shown; Push notification only is the default
- [ ] ✅ Step 4: Summary card shows correct title, body, audience, and channel before sending
- [ ] ⚠️ Tapping "Send" calls the `sendAnnouncement` Cloud Function — will fail with a functions/not-found error until Cloud Functions are deployed (Phase 22)
- [ ] ⚠️ Email channel options (Email only, Push + Email) silently depend on Blaze plan — selecting them without Blaze will deliver only push (or fail gracefully)

### Unread failure count badge (admin)

- [ ] ⚠️ Bell icon in admin AppBar shows a red badge with unread delivery failure count — requires Cloud Functions deployed and at least one failed delivery in Firestore to verify

### Email templates

- [ ] ✅ `/admin/notifications/templates` shows all templates from `emailTemplates` collection
- [ ] ✅ Empty state shown when collection is empty (templates are seeded by Cloud Functions on first run)
- [ ] ✅ Tapping a template opens the editor with the current subject and body pre-filled
- [ ] ✅ Editing subject or body enables the "Save" button in the AppBar
- [ ] ✅ Tapping "Save" writes the updated template to Firestore and shows a success snackbar
- [ ] ✅ `lastEditedByAdminId` and `lastEditedAt` are updated on save
- [ ] ✅ Substitution variable hint box displays the 6 supported variables

### Student notification centre

- [ ] ✅ Bell icon appears in `StudentHomeScreen` AppBar when a profile is loaded
- [ ] ✅ Unread notifications show a red count badge on the bell icon
- [ ] ✅ Bell icon not shown if no profile is selected
- [ ] ✅ Tapping the bell navigates to `/student/notifications`
- [ ] ✅ Notification list shows only student-visible types: grading eligibility, grading promotion, trial expiring, announcements
- [ ] ✅ Unread notifications have bold title, red dot, and subtle tinted background
- [ ] ✅ Tapping an unread notification marks it as read (`isRead = true`, `readAt` stamped in Firestore)
- [ ] ✅ "Mark all read" button marks all unread notifications in one action
- [ ] ✅ Empty state shown when no student-visible notifications exist
- [ ] ✅ Relative timestamps: "5m ago", "2h ago", "3d ago", "15 Jan 2026"
- [ ] ⚠️ Grading and announcement notifications only appear after Cloud Functions are deployed (Phase 22)

### Communication preferences

- [ ] ✅ Profile form shows 4 toggles: Billing & Payment, Grading, Trial Expiry, General Announcements
- [ ] ✅ Default is all-off (pre-launch, acceptable)
- [ ] ✅ Profile detail screen shows On/Off for each preference
- [ ] ✅ Preferences saved to Firestore as a map with 4 boolean keys
- [ ] ⚠️ Preferences are read by Cloud Functions to suppress opted-out notifications — only testable once Cloud Functions are deployed

---

## Dashboards

### Owner Dashboard

- [ ] ✅ Owner login lands at `/admin/dashboard` showing `OwnerDashboardScreen`
- [ ] ✅ Member metrics grid shows correct counts: Active, Trial, Lapsed, New this month
- [ ] ✅ Financial metrics grid shows PAYT outstanding total and cash received this month
- [ ] ✅ Alerts card appears when there are lapsed memberships, trials expiring in 7 days, >5 pending PAYT sessions, or coach DBS/first-aid within 30 days
- [ ] ✅ No alerts card shown when there are no alert conditions
- [ ] ✅ Membership growth chart renders a 6-month line chart (empty state shows 'No data yet')
- [ ] ✅ Attendance trend chart renders a 4-week bar chart
- [ ] ✅ Grading pass rate chart renders promoted/failed/absent bars for last 90 days
- [ ] ✅ Activity feed shows up to 10 most recent events across membership history, payments, announcements, gradings
- [ ] ✅ Pull-to-refresh invalidates chart and activity feed providers and reloads data
- [ ] ✅ Quick actions menu: Add member → profile form, Record payment → payment screen, Create session → session form, Send announcement → announcement screen

### Coach Dashboard

- [ ] ✅ Coach login lands at `/admin/dashboard` showing `CoachDashboardScreen` (not owner dashboard)
- [ ] ✅ AppBar shows coach's first name; "My Profile" button navigates to `/admin/my-profile`
- [ ] ✅ Today's sessions card lists only sessions for the coach's assigned disciplines
- [ ] ✅ Live attendee count pill updates in real time as students check in
- [ ] ✅ Tapping a session navigates to the session detail screen
- [ ] ✅ "No sessions scheduled today" shown when discipline has no sessions for today
- [ ] ✅ Compliance card shows DBS status badge and first-aid details
- [ ] ✅ DBS/first-aid expiry dates are colour-coded: red if expired, amber if within 30 days, grey otherwise
- [ ] ✅ Discipline summary cards show active member count and upcoming gradings (up to 3)
- [ ] ✅ Upcoming grading label shows "Today", "Tomorrow", or "In X days"

### Student Portal — role-based layouts

- [ ] ✅ Standard student (adult or junior): sees welcome card, Check In button, today's class list, membership card, inline grades
- [ ] ✅ Today's class list only shows sessions for the student's enrolled disciplines
- [ ] ✅ Inline grade cards show discipline name, current rank name, and grading count
- [ ] ✅ "See all" button navigates to the full grades screen
- [ ] ✅ Membership card shows plan type, renewal date (or trial end date), and status badge
- [ ] ✅ Dual-role (parent + student): TabBar with "My Training" and "Family" tabs
- [ ] ✅ My Training tab shows the student's own schedule, membership, and grades
- [ ] ✅ Family tab lists linked children with their discipline enrolments and current ranks
- [ ] ✅ Parent-only (no student profile types): shows family heading, membership card, linked children list
- [ ] ⚠️ Child cards resolve from `parentProfileId` / `secondParentProfileId` on the child's profile — test with a family membership where a junior is linked to a parent
- [ ] ⚠️ Student portal inactivity timeout resets on any tap or drag gesture — test across all three layout types

---

## Settings (Admin)

### Settings Screen (`/admin/settings`)

- [ ] ✅ Owner sees all 8 menu entries: General, Membership & Pricing, Notification Timings, GDPR & Data, Email Templates, Manage Team, Setup Wizard, Danger Zone
- [ ] ✅ Coach sees only "Manage Team" entry (and their own profile via dashboard, not settings)
- [ ] ✅ Tapping each entry navigates to the correct sub-screen

### General Settings (`/admin/settings/general`)

- [ ] ✅ Screen loads with Dojo Name, Dojo Email, and Privacy Policy Version pre-populated from Firestore
- [ ] ✅ All three fields are editable
- [ ] ✅ Saving without changing privacy version saves silently (no dialog)
- [ ] ✅ Changing the privacy version shows a confirmation dialog before saving
- [ ] ✅ Cancelling the version change dialog does NOT save
- [ ] ✅ Confirming the version change saves the new version and flags all active members with `requiresReConsent: true`
- [ ] ✅ Save button shows loading indicator while saving
- [ ] ✅ Success snackbar shown after save
- [ ] ✅ Error snackbar (red) shown if save fails

### Membership & Pricing (`/admin/settings/pricing`)

- [ ] ✅ All 8 membership price fields load with current Firestore values
- [ ] ✅ Prices display as numbers (no currency symbol in field)
- [ ] ✅ Non-numeric input shows validation error and disables Save
- [ ] ✅ Negative price shows validation error
- [ ] ✅ Saving unchanged prices shows no confirmation dialog; saves silently
- [ ] ✅ Changing any price shows a confirmation dialog listing changed plans with old → new values
- [ ] ✅ Cancelling the price change dialog does NOT save
- [ ] ✅ Confirming saves new prices to `membershipPricing` collection and writes a `pricingChangeLogs` document for each changed plan
- [ ] ✅ `pricingChangeLogs` document contains: planTypeKey, previousAmount, newAmount, changedByAdminId, changedAt
- [ ] ⚠️ Verify that price changes do NOT retroactively update existing membership records

### Notification Timings (`/admin/settings/notifications`)

- [ ] ✅ All 7 timing fields load with current Firestore values (or defaults if not set)
- [ ] ✅ Each field accepts only whole numbers between 1 and 365
- [ ] ✅ Value below 1 shows inline validation error on the field
- [ ] ✅ Value above 365 shows inline validation error on the field
- [ ] ✅ Non-integer input shows inline validation error
- [ ] ✅ Save button is disabled while any field has a validation error
- [ ] ✅ Save button enabled once all fields are valid
- [ ] ✅ Saving writes all 7 keys to `appSettings` in Firestore
- [ ] ✅ Success snackbar shown after save

### GDPR & Data (`/admin/settings/gdpr`)

**Retention Period**

- [ ] ✅ Lapsed member retention field loads with current `gdprRetentionMonths` (default 12)
- [ ] ✅ Field accepts positive integers only (minimum 1)
- [ ] ✅ Invalid value disables Save Retention Period button
- [ ] ✅ Financial retention info box is read-only (7 years, not editable)
- [ ] ✅ Saving updates `gdprRetentionMonths` in Firestore

**Bulk Anonymisation**

- [ ] ✅ Eligible count loads from Firestore (members whose membership has lapsed and retention period has expired)
- [ ] ✅ "No members are currently eligible" shown when count is 0; button disabled
- [ ] ✅ Count > 0 enables "Run Anonymisation" button with count in label
- [ ] ✅ Tapping button shows confirmation dialog with exact count
- [ ] ✅ Cancelling confirmation does nothing
- [ ] ⚠️ Confirming calls `bulkAnonymise` Cloud Function (not yet deployed — expect graceful error snackbar)
- [ ] ✅ After successful anonymisation, eligible count reloads and decrements to 0

**Bulk Data Export**

- [ ] ✅ "Export All Member Data" button opens format selection dialog
- [ ] ✅ Dialog offers CSV, PDF, Both as SegmentedButton options
- [ ] ✅ Tapping Export closes dialog and shows "not yet available" snackbar (CF not deployed)

### Email Templates (`/admin/settings/email-templates`)

- [ ] ✅ Lists all 10 template entries with names and descriptions
- [ ] ✅ "Edit Templates" button navigates to `/admin/notifications`
- [ ] ✅ No editing happens on this screen itself

### Danger Zone (`/admin/settings/danger`)

- [ ] ✅ Red warning banner visible at top of screen
- [ ] ✅ Clear Notification Logs: input accepts number of days (1–365)
- [ ] ✅ Invalid day count disables Clear button
- [ ] ✅ Valid day count enables Clear button
- [ ] ✅ Tapping Clear shows confirmation dialog
- [ ] ✅ Cancelling confirmation does nothing
- [ ] ⚠️ Confirming calls `clearNotificationLogs` Cloud Function (not yet deployed — expect graceful error snackbar)

### Re-Consent Banner (Profile Detail)

- [ ] ✅ Amber "Re-consent required" banner visible at top of profile detail when `requiresReConsent: true`
- [ ] ✅ Banner NOT visible when `requiresReConsent: false`
- [ ] ✅ "Record Re-Consent" button on banner shows confirmation dialog
- [ ] ✅ Cancelling dialog does nothing
- [ ] ✅ Confirming sets `requiresReConsent: false`, updates `dataProcessingConsentVersion` to current privacy policy version, and sets `dataProcessingConsentDate` to now
- [ ] ✅ Banner disappears immediately after recording re-consent (no manual refresh)
- [ ] ⚠️ Verify that after a privacy version bump, ALL active non-anonymised profiles have `requiresReConsent: true` (check a sample in Firestore console)


---

## Session F — Grading Quality Improvements

### Inactive discipline guard (`CreateGradingEventUseCase`)

- [ ] ✅ Creating a grading event for an active discipline succeeds as normal
- [ ] ⚠️ If a programmatic call passes an inactive disciplineId, use case throws `ArgumentError` with the discipline name — currently no UI path triggers this since `create_grading_event_screen.dart` already filters to active disciplines

### Minimum attendance warning (`NominateStudentsScreen`)

- [ ] ✅ Nominating students with no `minAttendanceForGrading` set on their next rank proceeds without any dialog
- [ ] ✅ Nominating a student whose attendance count is ≥ the minimum proceeds silently
- [ ] ✅ Nominating a student whose attendance count is below the minimum shows the warning dialog
- [ ] ✅ Warning dialog lists student name, actual count, required count, and target rank name
- [ ] ✅ Multiple students below threshold: all listed in a single dialog (not one dialog per student)
- [ ] ✅ "Cancel" in warning dialog aborts the nomination — no records written
- [ ] ✅ "Nominate Anyway" in warning dialog proceeds and writes all nominations
- [ ] ✅ Students already at the top rank (no next rank) — no attendance check, nominated silently
- [ ] ⚠️ Attendance count fetches run serially per student — may be slow for large selections
- [ ] ⚠️ If rank data hasn't loaded yet when admin taps Nominate, check is skipped (fail open)


---

## Bug Fix — Setup Wizard Blank Content Area

### Symptom
PageView with NeverScrollableScrollPhysics rendered a blank white area under the step-indicator header on Android.

### Fix
Replaced PageView + PageController with IndexedStack.

- [ ] ✅ Open the app on a fresh Firebase project (no setup doc) — wizard opens to Welcome page, content visible (navy icon box, welcome text, three info tiles)
- [ ] ✅ "Continue" button visible and tappable in nav bar
- [ ] ✅ Tapping Continue advances to Owner Account page (step 2 dot highlights)
- [ ] ✅ Navigating Back from page 2 returns to Welcome — form fields on page 2 retain their values (IndexedStack preserves state)
- [ ] ✅ Complete all 4 pages with valid data — "Finish Setup" creates Firebase Auth user, writes Firestore docs, redirects to login
- [ ] ✅ After setup is complete, revisiting /admin/setup redirects to login (setup guard active)
- [ ] ⚠️ On a device where the previous PageView was blank, confirm the same device now renders correctly

---

## Phase 3 — Self Sign-Up Wizard

### Wizard navigation
- [ ] ✅ Tapping "Create account" on the login screen navigates to step 1 (Account details)
- [ ] ✅ Progress bar shows "Step 1 of 10" and fills correctly as steps advance
- [ ] ✅ AppBar title changes to the correct step title on each step
- [ ] ✅ "Next" button validates the current step and refuses to advance if invalid (shows inline error messages)
- [ ] ✅ Back button (step > 1) or Android back gesture returns to the previous step, preserving filled data
- [ ] ✅ Close button (step 1) dismisses the wizard and returns to the login screen
- [ ] ✅ Step 8 (Membership) shows the free-trial card with no user input required — "Next" advances without interaction

### Step-by-step validation
- [ ] ✅ Step 1: email format validated; password minimum 8 characters; confirm-password must match
- [ ] ✅ Step 2: first name, last name, date of birth, address fields all required; phone minimum 7 digits
- [ ] ✅ Step 2: enabling "I have children" shows a child form; disabling clears children from state
- [ ] ✅ Step 2: adding and removing multiple children works; each child requires first name, last name, DOB
- [ ] ✅ Step 2: date pickers open, enforce min/max date limits (adults: 1900–today; children: last 18 years–today)
- [ ] ✅ Step 3: emergency contact name, relationship, and phone all required
- [ ] ✅ Step 5: wizard refuses to advance with "Please select at least one discipline" if none selected; selecting disciplines works
- [ ] ✅ Step 6: wizard refuses to advance unless the GDPR consent checkbox is ticked
- [ ] ✅ Step 9: PIN must be exactly 4 digits; confirm PIN must match

### Review step
- [ ] ✅ Step 10 shows all entered data correctly (name, address, emergency contact, consents, disciplines count)
- [ ] ✅ "Edit" links on each section navigate back to the correct step
- [ ] ✅ After editing a section from review, returning to step 10 (via "Next" through remaining steps) shows updated values

### Submission
- [ ] ✅ Tapping "Create account" on step 10 shows a loading overlay and disables the button
- [ ] ✅ On success: router redirects to the email verification screen (no manual navigation needed)
- [ ] ✅ On success: Firebase Auth account exists for the new email
- [ ] ✅ On success: a profile document appears in Firestore `profiles` collection with correct data, uid, selfRegistered=true, registrationStatus=pendingVerification
- [ ] ✅ On success: owners receive a `selfRegistration` notification in their admin notification list
- [ ] ⚠️ If registering a parent with children: parent profile has profileTypes=[parentGuardian]; child profiles exist with profileTypes=[juniorStudent], parentProfileId set to parent doc ID, and emergency contact auto-set to parent name/phone
- [ ] ⚠️ Coaches assigned to a selected discipline also receive a `selfRegistration` notification; coaches NOT assigned to any selected discipline do NOT
- [ ] ⚠️ Entering an email already registered with Firebase Auth produces a meaningful error message on step 10 (not a crash)
- [ ] ⚠️ On submission failure the loading overlay clears, the error message banner appears on the review step, and the user can retry

---

## Phase 4 — Student Mobile Portal

### Navigation & drawer
- [ ] ✅ After email verification, app lands on student portal Home screen
- [ ] ✅ Hamburger icon opens the side drawer from any portal screen
- [ ] ✅ Drawer header shows correct initials, display name, and role label (Student / Junior Student / Parent / Guardian)
- [ ] ✅ Active nav item is highlighted in accent colour
- [ ] ✅ "Family" nav item only appears for parent/guardian profiles
- [ ] ✅ All six nav items route to their correct screens without errors
- [ ] ✅ Sign Out in the drawer (and on Account screen) signs out and returns to the entry/login screen

### Home screen
- [ ] ✅ Greeting uses correct time-of-day (Good morning / afternoon / evening) and student's first name
- [ ] ✅ Membership summary card shows plan type, status badge, and renewal date (or "No active membership" if none)
- [ ] ✅ "My Disciplines" section lists active enrolments with discipline name and current rank (or "Ungraded")
- [ ] ✅ "Recent Notifications" shows up to 3 most recent push notifications; unread items have an accent dot
- [ ] ✅ "See all" links on each section navigate to the corresponding detail screen
- [ ] ✅ Pull-to-refresh reloads all three sections
- [ ] ⚠️ If the student has no enrolments, the "My Disciplines" section shows the empty-state message

### Grades screen
- [ ] ✅ Lists all active enrolments with discipline name and current rank
- [ ] ✅ Belt colour swatch matches the rank's colourHex (small coloured bar on the right)
- [ ] ✅ Shows "Ungraded" for enrolments with no current rank ID
- [ ] ⚠️ If the student has no active enrolments, the empty-state ("No disciplines yet") is shown

### Membership screen
- [ ] ✅ Active membership shows plan type, status badge, and all relevant dates (trial start/end, member since, next renewal, cancelled on)
- [ ] ✅ Status badge colour: active=green, trial=amber, lapsed=red, cancelled/expired=grey, PAYT=blue
- [ ] ✅ "speak to the dojo team" info box is shown below membership details
- [ ] ⚠️ Account with pending registration status shows "Account pending" message with correct explanation text
- [ ] ⚠️ Account with no membership at all shows "No active membership" card

### Schedule screen
- [ ] ✅ Shows "Schedule coming soon" placeholder with calendar icon (no errors)

### Notifications screen
- [ ] ✅ Lists all push notifications ordered most-recent first, with title, body excerpt, and timestamp
- [ ] ✅ Unread notifications show an accent dot indicator
- [ ] ✅ Tapping an unread notification calls markReadAt and the dot disappears on next stream update
- [ ] ⚠️ Email-only notifications (no title or body) are filtered out and do not appear in the list
- [ ] ⚠️ Empty state ("No notifications yet") shown if student has received no push notifications

### Family screen
- [ ] ✅ Parent/guardian profile: lists linked junior profiles with initials avatar, name, and date of birth
- [ ] ✅ Empty state shown if no juniors are linked
- [ ] ⚠️ Non-parent accessing /student-portal/family will see the empty state (no juniors linked to their ID)

### Account screen
- [ ] ✅ Shows avatar with initials, full name, and email at top
- [ ] ✅ Personal details section: date of birth, gender (if set), phone
- [ ] ✅ Address section: all address fields including optional line 2
- [ ] ✅ Emergency contact section: name, relationship, phone
- [ ] ✅ Medical notes section only shown if allergiesOrMedicalNotes is non-empty
- [ ] ✅ "Sign Out" button signs out and returns to entry screen

---

## Phase 5 — Kiosk Mode

### Activation
- [ ] ✅ Owner dashboard AppBar shows the tablet icon button
- [ ] ✅ Tapping the tablet icon opens the "Activate Kiosk Mode" dialog with a PIN field and explanatory text
- [ ] ✅ Tapping "Cancel" dismisses the dialog without activating kiosk mode
- [ ] ✅ Submitting with fewer than 4 digits shows validation error "PIN must be exactly 4 digits"
- [ ] ✅ Submitting with a non-numeric value shows validation error
- [ ] ✅ Submitting a valid 4-digit PIN activates kiosk mode and navigates to the student select screen
- [ ] ✅ While kiosk mode is active, any attempt to navigate to an admin route is intercepted and redirected to the student select screen
- [ ] ⚠️ Coach dashboard does NOT show the kiosk activation button (it is owner-only)

### Student select screen in kiosk mode
- [ ] ✅ Back arrow is hidden when kiosk mode is active
- [ ] ✅ A lock icon button appears in the AppBar trailing position when kiosk mode is active
- [ ] ✅ Back arrow is visible (and works) when kiosk mode is NOT active

### Exit flow
- [ ] ✅ Tapping the lock icon opens the "Exit Kiosk Mode" PIN dialog
- [ ] ✅ Tapping "Cancel" dismisses the dialog and stays in kiosk mode
- [ ] ✅ Entering an incorrect PIN shows "Incorrect PIN" error and clears the field; kiosk mode remains active
- [ ] ✅ Entering the correct PIN deactivates kiosk mode and navigates to the entry screen (which redirects to admin dashboard if admin is still authenticated)
- [ ] ⚠️ Kiosk mode state is session-only — restarting the app returns to normal mode

---

## Phase — Membership Payments (Student Portal)

### Stripe plan selection sheet
- [ ] ✅ Tapping "Choose a Plan" on trial/lapsed/expired membership opens the plan selection sheet
- [ ] ✅ All 5 plans display with correct names and pricing
- [ ] ✅ The current plan (if any) is highlighted / labelled
- [ ] ✅ Selecting a cheaper plan shows a "downgrade" confirmation message
- [ ] ✅ Selecting a more expensive plan shows an "upgrade" confirmation message
- [ ] ✅ Tapping a plan calls StripeService and presents the payment sheet
- [ ] ⚠️ Payment sheet requires valid Stripe publishable key in app config — test in Stripe test mode only
- [ ] ⚠️ StripeService Cloud Functions (`createStripeCustomer`, `createStripeSubscription`, etc.) are not yet deployed — tapping any Stripe action will fail gracefully with an error snackbar

### Grace period
- [ ] ✅ A membership with `status: gracePeriod` shows a warning banner on the membership card
- [ ] ✅ The banner displays the `gracePeriodEnd` date
- [ ] ✅ "Update Payment Details" button appears (shows informational snackbar until Stripe webhook wires it up)
- [ ] ✅ Grace period status appears as "Grace Period" (amber) in admin membership list, profile detail, and student portal

### Cancel membership
- [ ] ✅ "Cancel Membership" button appears for active Stripe-based memberships with no pending downgrade
- [ ] ✅ Cancel confirmation dialog shows the renewal date ("active until…")
- [ ] ✅ Confirming cancel calls `cancelAtPeriodEnd` — membership stays active until period end
- [ ] ✅ After cancel, the button changes to show pending downgrade info (no second cancel option)

### Pending downgrade notice
- [ ] ✅ If `pendingDowngradePlanId` is set, the membership card shows a "Scheduled downgrade to X on [date]" notice
- [ ] ✅ No "Upgrade Plan" or "Cancel" buttons appear when a downgrade is already pending

---

## Phase — Admin Invite Flow

### Sending an invite (admin side)
- [ ] ✅ Opening a student profile shows an "Invite" section (not shown for coaches or parent-only profiles)
- [ ] ✅ Invite section shows status badge: "Not Sent" (grey), "Pending" (amber), "Accepted" (green), "Expired" (red)
- [ ] ✅ "Send Invite" button appears for `notSent` or `expired` status
- [ ] ✅ "Resend Invite" button appears for `pending` status
- [ ] ✅ Tapping the button updates `inviteStatus: pending`, `inviteExpiresAt: now + 24h` in Firestore
- [ ] ⚠️ The `sendStudentInviteEmail` Cloud Function is not yet deployed — the Firestore update still happens, but no email is sent
- [ ] ✅ After tapping, the invite section refreshes to show "Pending" status and the sent date
- [ ] ✅ Profile list shows a "Pending Invites (N)" chip with the count from `pendingInvitesProvider`
- [ ] ✅ Tapping the pending invites chip filters the list to only pending-invite profiles
- [ ] ✅ All type chips reset the pending-invites filter when tapped

### Accepting an invite (student side)
- [ ] ✅ Deep link `/invite/accept?profileId=<id>` opens `AcceptInviteScreen`
- [ ] ✅ If the profile is not found, redirects to `InviteExpiredScreen`
- [ ] ✅ If `inviteExpiresAt` is in the past or `inviteStatus == expired`, redirects to `InviteExpiredScreen?profileId=<id>`
- [ ] ✅ Valid invite shows "Welcome, [FirstName]!" and the password step
- [ ] ✅ Password validation: minimum 8 characters, confirm must match
- [ ] ✅ Tapping Continue on the password step advances to the PIN step
- [ ] ✅ PIN step: 4 individual digit boxes, auto-focus advances on each digit entered
- [ ] ✅ Backspace in a PIN box returns focus to the previous box
- [ ] ✅ Tapping "Activate account" with a 4-digit PIN triggers activation:
  - Creates a Firebase Auth user with the profile's email + chosen password
  - Updates profile: `uid`, `inviteStatus: accepted`, `emailVerified: true`
  - Sets the PIN hash
  - Navigates to the student portal home
- [ ] ✅ If activation fails (e.g. email already in use), returns to the password step with an error message
- [ ] ✅ Back button is hidden on the account setup screen (no way to accidentally navigate back mid-flow)

### Expired invite screen
- [ ] ✅ Shows "This invite has expired" message with a link-off icon
- [ ] ✅ "Request a new invite" button shown if `profileId` is in the URL
- [ ] ✅ Tapping "Request a new invite" calls the `requestInviteResend` Cloud Function (shows success snackbar)
- [ ] ⚠️ `requestInviteResend` Cloud Function not yet deployed — snackbar will still show (error is caught silently)
- [ ] ✅ "Contact the dojo directly" button opens a simple dialog

---

## Phase — Notification Preferences & Unread Badge

### Notification preferences (student portal account screen)
- [ ] ✅ "Notification preferences" card is visible on the Account screen
- [ ] ✅ "Billing & payment reminders" toggle is locked on with a "Always sent" subtitle
- [ ] ✅ Membership status changes, grading notifications, trial expiry reminders, and general announcements each have a working toggle
- [ ] ✅ Toggling a preference immediately updates the profile in Firestore
- [ ] ✅ Toggling off and back on persists correctly (no optimistic state — reads from live stream)

### Unread badge on drawer
- [ ] ✅ Notifications drawer item shows a red badge with the count of unread notifications
- [ ] ✅ Badge disappears when all notifications are read (count = 0)

---

## Class titles and recurring sessions

### Create wizard — title
- [ ] ✅ Step 1 prompts for a class name with hint text "Kids Karate Class, Adults BJJ…"
- [ ] ✅ Next button is disabled until at least one non-whitespace character is entered
- [ ] ✅ Title carries through to the confirm summary screen
- [ ] ✅ Creating a session with no title (blank) still works — discipline name is used as fallback in the AppBar and header

### Create wizard — date (future dates)
- [ ] ✅ Date picker allows selecting future dates (max restriction removed)
- [ ] ✅ Past dates are still selectable for back-logging

### Create wizard — recurring
- [ ] ✅ Recurring step shows the day derived from the chosen date (e.g. "Repeats every Wednesday")
- [ ] ✅ Toggle defaults to off; toggling on shows the info banner "Sessions will be created every [day] for 1 year"
- [ ] ✅ Confirm screen shows "Weekly every [day] (52 sessions)" when recurring is on
- [ ] ✅ Confirm button reads "Create 52 Sessions" when recurring is on
- [ ] ✅ After saving a recurring class, Firestore contains exactly 52 sessions all sharing the same `recurringGroupId`
- [ ] ✅ All 52 sessions have `isRecurring: true`, the same `disciplineId`, `title`, `startTime`, `endTime`
- [ ] ✅ Sessions are 7 days apart; first is the chosen start date
- [ ] ⚠️ Queue resolution only fires for the session whose date matches today; future sessions are silently skipped (expected behaviour)

### Session detail — title and recurring badge
- [ ] ✅ Title is shown as the primary heading in the header card; discipline name appears below it
- [ ] ✅ AppBar title uses the class title (or discipline name if no title)
- [ ] ✅ "Recurring · Weekly" badge is visible for recurring sessions; absent for one-off sessions

### Edit recurring session
- [ ] ✅ Edit icon is shown on the header of recurring sessions; absent on one-off sessions
- [ ] ✅ Tapping edit shows a bottom sheet with "This session only" and "This and all future sessions"
- [ ] ✅ "This session only" — updates only the tapped session's title/times/notes in Firestore; all other sessions in the series are unchanged
- [ ] ✅ "This and all future sessions" — updates all sessions in the group whose `sessionDate` ≥ this session's date; past sessions in the same series are unchanged
- [ ] ✅ Editing with an end time before start time shows a validation error; does not save
- [ ] ✅ Cancelling the dialog makes no changes
- [ ] ⚠️ Marking notifications as read is not yet built — the `isRead` field exists on `NotificationLog` but no UI or function marks them read yet

### Design system — tokens (tokens.html)
- [ ] ✅ App background renders as washi paper #F3EBDD (paper-1), not white
- [ ] ✅ Primary action colour is crimson #8B2A1F; no navy or generic red
- [ ] ✅ Belt colours use exact design values (e.g. black = #15120E, purple = #6E3B8C, not generic Flutter colours)
- [ ] ✅ Headings use Noto Serif JP; body/labels use IBM Plex Sans / IBM Plex Mono via Google Fonts
- [ ] ✅ Dark theme: scaffold background is dark umber #1A1815; text is #F0E8D8; crimson brightens to #C74A3B

### Component library — widgets (components.html)
- [ ] ✅ AppButton primary: crimson bg, paper-0 text, darkens on press, 40px height
- [ ] ✅ AppButton secondary: transparent bg, ink-1 border; press inverts to ink-1 bg + paper-0 text
- [ ] ✅ AppButton destructive: transparent bg, error border; press fills error red
- [ ] ✅ AppButton text: no border, crimson text
- [ ] ✅ AppButton loading: spinner + label shown; button is inert while loading
- [ ] ✅ AppButton sm/lg sizes render at 32px / 52px heights
- [ ] ✅ AppIconButton: 40×40, hairline border, darkens on press
- [ ] ✅ AppFab: 56×56 circle, crimson, sh-3 shadow
- [ ] ✅ AppTextField: mono eyebrow label above field; crimson border on focus; error text below in error state
- [ ] ✅ AppSearchField: leading magnifier icon; 40px height
- [ ] ✅ AppToggle: 44×24 pill; thumb slides; crimson when on
- [ ] ✅ AppCheckbox: 20×20, 3px radius; ink-1 fill with tick when checked
- [ ] ✅ PinDots: dots fill/empty animatedly; turn error-red on failed attempt
- [ ] ✅ PinKeypad: 64×64 circle keys with hairline border; CLEAR and backspace keys transparent
- [ ] ✅ MembershipBadge: shows correct colour/wash per status (active=green, lapsed=red, trial=indigo, expiringSoon=ochre, expired/cancelled=grey)
- [ ] ✅ RoleBadge: adult=indigo, junior=tea, coach=crimson, parent=ochre — no leading dot
- [ ] ✅ DisciplineChip: pill shape, coloured dot matches discipline colour
- [ ] ✅ BeltStrip: correct colour, sheen overlay; white belt has hairline border not sheen; stripe tab renders on right for striped belts
- [ ] ✅ MemberAvatar: shows initials in Noto Serif JP; sm/md/lg/xl sizes correct
- [ ] ✅ AppCard: paper-0 bg, hairline border, sh-1 shadow; press animates down 1px when onTap provided
- [ ] ✅ DotDivider: dotted hairline line renders inside cards
- [ ] ✅ MemberListTile: avatar | name+belt | role badge | status badge; hairline divider between rows
- [ ] ✅ StepIndicator: done steps show tick + ink-1 bg; current = crimson; pending = hairline; lines connect steps
- [ ] ✅ EmptyState: seal glyph in crimson stamp at –3°; title in display font; optional CTA button
- [ ] ✅ SkeletonBox: shimmer animation paper-3→paper-2→paper-3 cycles at 1.4s
- [ ] ✅ SkeletonListTile: avatar circle + two text lines shown as skeleton rows

---

## Owner Dashboard — Redesign (admin-dashboard.html)

### Stat cards
- [ ] ✅ Four stat cards render in a 4-column row on wide screens (≥500px) and 2×2 grid on narrow screens
- [ ] ✅ "Active members" card shows total count with "X adults · Y juniors" subtitle when data is present
- [ ] ✅ "Trials expiring" card shows ochre left border when trialCount > 0; no border when 0
- [ ] ✅ "Memberships lapsed" card shows error-red left border when lapsedCount > 0; shows "All clear" subtitle when 0
- [ ] ✅ "Sessions this week" card shows session count and check-in count subtitle; shows "—" while loading
- [ ] ✅ Stat card numbers use large display text (36px Noto Serif JP)

### Greeting & date label
- [ ] ✅ AppBar title shows "Good morning/afternoon/evening, [name]" based on local time
- [ ] ✅ "At a glance · [day] [date] [month]" label renders above stat cards

### Layout
- [ ] ✅ On wide screens (≥600px): activity feed (2/3) and sidebar (1/3) render side by side
- [ ] ✅ On narrow screens (<600px): sidebar stacks above activity feed

### Activity feed
- [ ] ✅ Timestamp shows HH:mm for today's entries, Xm/Xd/d MMM for older entries
- [ ] ✅ Coloured dots: payments=tea, grading=crimson, announcements=indigo, membership changes=ochre, default=ink-3
- [ ] ✅ "View all →" button visible (placeholder for now)
- [ ] ✅ Empty state and error state render gracefully

### Attention panel
- [ ] ✅ Attention panel hides entirely when there are no alerts
- [ ] ✅ Error-severity alerts show crimson badge, warning-severity show ochre badge
- [ ] ✅ Multiple alerts separated by dividers

### Quick actions
- [ ] ✅ "Add" tile navigates to Add Member screen
- [ ] ✅ "Record" tile navigates to Record Payment screen
- [ ] ✅ "Mark" tile navigates to Create Attendance Session screen

### Upcoming grading
- [ ] ✅ Upcoming grading panel hides when there are no upcoming events
- [ ] ✅ Shows next upcoming grading date and title
- [ ] ✅ "Review shortlist →" navigates to the correct grading detail screen
- [ ] ⚠️ Panel hides while loading and on error (silent failure — acceptable for a dashboard widget)

### Kiosk mode
- [ ] ✅ Kiosk Mode button in AppBar still opens PIN dialog and activates correctly

---

## Coach Dashboard — Redesign (admin-dashboard-coach.html)

### Greeting header
- [ ] ✅ AppBar shows time-aware greeting ("Good morning/afternoon/evening, [firstName]")
- [ ] ✅ Greeting sub-header shows date/time + "X sessions left this week" summary text
- [ ] ✅ "One session left" uses singular form; "No more sessions this week" shows when count is 0
- [ ] ✅ Discipline scope tags render for each assigned discipline with coloured dot + name
- [ ] ✅ Scope tags use correct discipline colours (karate=crimson, judo=indigo, kendo=ink-2, etc.)

### Layout
- [ ] ✅ Wide (≥600px): left column (sessions + gradings) and right column (compliance + summary + actions) side by side
- [ ] ✅ Narrow (<600px): panels stack — sessions → gradings → right column

### Today's sessions panel
- [ ] ✅ Live pulsing green dot animates continuously in panel header
- [ ] ✅ Sessions sorted by start time ascending
- [ ] ✅ Each row shows: start/end time (monospace) | discipline dot + title | check-in fraction + progress bar
- [ ] ✅ "Up next" tag (amber) appears for sessions starting within 60 minutes
- [ ] ✅ "In progress" tag appears once session start time has passed (until end time)
- [ ] ✅ Progress bar turns amber (ochre) when ≥90% capacity
- [ ] ✅ Enrolled count denominator uses discipline active member count
- [ ] ✅ Empty state: "空" glyph + "No classes today." + "Create session" button
- [ ] ✅ Loading skeleton: two shimmer rows animate paper-2→paper-3→paper-2

### Upcoming gradings panel
- [ ] ✅ Gradings from all assigned disciplines combined and sorted by date, capped at 3
- [ ] ✅ Calendar date block shows day abbreviation, numeric day, month abbreviation
- [ ] ✅ "+ Create event" button navigates to grading create screen
- [ ] ✅ Row tap navigates to grading detail screen

### Compliance panel
- [ ] ✅ DBS and First Aid rows render for coach's own profile
- [ ] ✅ "Clear" state: no coloured left border, green badge
- [ ] ✅ "Warn" state (expiring <60 days): ochre left border, "Renew soon" badge
- [ ] ✅ "Danger" state (expired): error-red left border, "Action required" badge
- [ ] ✅ "Pending verification" row appears when dbs.pendingVerification is true (indigo treatment)
- [ ] ✅ Panel shows "Compliance profile not found" gracefully if CoachProfile not loaded
- [ ] ⚠️ "Update" button navigates to My Profile — test DBS update flow end-to-end

### Discipline summary panel
- [ ] ✅ One row per assigned discipline: coloured swatch | name | enrolled | lapsed | PAYT
- [ ] ✅ Lapsed and PAYT counts show in ochre when >0
- [ ] ✅ Panel hides when coach has no assigned disciplines

### Quick actions panel
- [ ] ✅ Dark ink-1 background with paper-0 text
- [ ] ✅ First action is contextual: "Mark attendance — [first discipline name]"
- [ ] ✅ All three actions navigate to correct screens
- [ ] ✅ Row hover/tap ripple visible on mobile and desktop

---

## Members list redesign (design handoff — admin-members.html)

### Filter bar
- [ ] ✅ Search field: paper-0 background, hairline border, r-sm radius, IBM Plex Sans 14px
- [ ] ✅ Search filters member list in real time as you type
- [ ] ✅ Role chips show live counts (All, Adults, Juniors, Coaches, Parents)
- [ ] ✅ Role chips use Ichiban mono style: uppercase, pill shape, ink-1 bg when active
- [ ] ✅ Tapping a role chip filters the list to that type only; tapping again deselects (back to All)
- [ ] ✅ Status chip cycles: Any → Active → Trial → Lapsed → Any on each tap
- [ ] ✅ "Discipline · Any" chip is shown but does not yet filter (deferred)

### Table header row
- [ ] ✅ Paper-2 background, IBM Plex Mono 10px uppercase ink-3 labels
- [ ] ✅ Column headers: Name, Discipline · Rank, Role, Status
- [ ] ✅ Header columns visually align with data rows

### Member rows
- [ ] ✅ Avatar: 32px circle, Noto Serif JP initials, paper-3 bg, hairline border
- [ ] ✅ Name: IBM Plex Sans 14px w500 ink-1
- [ ] ✅ Subtitle: IBM Plex Mono 11px ink-3 — format "N y · joined Mon YYYY"
- [ ] ✅ Belt strip + rank label shown when member has an active enrolment
- [ ] ✅ Kendo members show KendoRankChip (dashed border, 剣 prefix) instead of belt strip
- [ ] ✅ Role badge matches profile type (Coach=crimson, Junior=tea, Adult=indigo, Parent=ochre)
- [ ] ✅ Status badge reflects profile.registrationStatus (Active/Trial/Lapsed)
- [ ] ✅ Row tap navigates to profile detail screen
- [ ] ✅ Hairline divider between rows

### Empty state
- [ ] ✅ With active filters: "No members match your filters." + "Clear filters" button
- [ ] ✅ Clear filters resets search, type chip, and status chip
- [ ] ✅ Without filters (truly empty): "No members yet. Tap + to add the first one."

### AppBar actions
- [ ] ✅ "Export CSV" outlined button is present (no-op for now)
- [ ] ✅ "+ Add member" crimson filled button navigates to create profile screen
