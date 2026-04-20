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
- [ ] ⚠️ Membership summary section shows placeholder text — expected

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
| Membership summary on profile detail is a placeholder | Memberships feature |
| Student home and check-in screens are fully built ✅ | — |
| Student attendance history and grades screens are still placeholders | Student features |
| Dashboard is a placeholder | Dashboard feature |
| Settings, Notifications, Payments screens are placeholders | Respective features |
| PAYT session recording on check-in not yet built | Memberships feature |
| Lapsed membership flag on dashboard not yet built | Memberships feature |
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
