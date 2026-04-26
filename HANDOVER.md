# Ichiban App — Full Project Handover

**Date produced:** 24 April 2026
**Purpose:** Complete context for a new Claude chat session to continue development without any prior conversation history.

---

## 1. Project Overview

**Ichiban** is a dojo management application for a martial arts club. It is built in Flutter and targets two separate app flavours:

| Flavour | Entry point | Purpose |
|---|---|---|
| **admin** | `lib/main_admin.dart` | Club administrators manage profiles, memberships, disciplines, grading, attendance, payments |
| **student** | `lib/main_student.dart` | Students view their own profile, attendance history, and grades; check in to sessions |

**Tech stack:**
- Flutter / Dart (SDK ^3.11.4) — Flutter SDK at `G:\flutter` (no spaces — important for test runner)
- Firebase (Auth, Firestore, Cloud Messaging)
- Riverpod 3 for state management (`flutter_riverpod: ^3.1.0`)
- go_router 17 for navigation
- equatable for entity equality
- intl for date formatting
- crypto for PIN hashing
- share_plus for CSV export (financial report)

**Git worktree (active branch):**
`G:\Ichiban app\Ichiban App\.claude\worktrees\confident-driscoll\`
Branch: `claude/confident-driscoll`

All work should be done in the worktree path above, not the main project root.

**After generating any code always run in order:**
```
cd "G:\Ichiban app\Ichiban App\.claude\worktrees\confident-driscoll"
flutter pub get
dart format .
flutter analyze
```
Fix all warnings before considering the task complete.

---

## 2. Architecture

Clean Architecture with three layers:

```
lib/
├── domain/          ← Pure Dart. No Flutter, no Firebase.
│   ├── entities/    ← Immutable data classes (Equatable)
│   ├── repositories/← Abstract interfaces only
│   └── use_cases/   ← Business logic, validation
│
├── data/            ← Firebase implementations
│   ├── firebase/
│   │   ├── converters/         ← Firestore ↔ entity conversion
│   │   └── firestore_collections.dart  ← Central typed collection refs
│   └── repositories/           ← FirestoreXxxRepository implements XxxRepository
│
└── core/            ← App-wide infrastructure
    ├── constants/   ← AppConstants (collection names, PIN length, etc.)
    ├── errors/      ← AppException, Failures
    ├── providers/   ← Riverpod providers (use cases + streams)
    ├── router/      ← AppRouter, RouteNames
    ├── theme/       ← AppColors, AppTextStyles, AppTheme
    └── utils/       ← DatabaseSeeder

lib/presentation/features/
├── auth/
├── profiles/
├── disciplines/
├── memberships/
├── enrollment/
├── attendance/
├── grading/
├── payments/
└── student/
```

**Design system source of truth:** `lib/core/theme/app_theme.dart`
Never hardcode colours, font sizes, or spacing values in widgets. Add tokens there first, then reference them.

---

## 3. Firestore Collections

All collection names are constants in `lib/core/constants/app_constants.dart`.

| Firestore collection | Dart constant | Entity |
|---|---|---|
| `profiles` | `colProfiles` | `Profile` |
| `disciplines` | `colDisciplines` | `Discipline` |
| `disciplines/{id}/ranks` | `colRanks` | `Rank` (subcollection) |
| `memberships` | `colMemberships` | `Membership` |
| `membershipPricing` | `colMembershipPricing` | `MembershipPricing` |
| `paytSessions` | `colPaytSessions` | `PaytSession` |
| `cashPayments` | `colCashPayments` | `CashPayment` |
| `enrollments` | `colEnrollments` | `Enrollment` |
| `gradingEvents` | `colGradingEvents` | `GradingEvent` |
| `gradingRecords` | `colGradingRecords` | `GradingRecord` |
| `attendanceSessions` | `colAttendanceSessions` | `AttendanceSession` |
| `attendanceRecords` | `colAttendanceRecords` | `AttendanceRecord` |
| `notificationLogs` | `colNotificationLogs` | `NotificationLog` |
| `emailTemplates` | `colEmailTemplates` | `EmailTemplate` |
| `appSettings` | `colAppSettings` | `AppSetting` |

**Pattern:** All collections use `withConverter` via `FirestoreCollections`. Repositories never call `.data()` manually.

```dart
// Usage in a repository
final snap = await FirestoreCollections.profiles().doc(id).get();
final profile = snap.data(); // already a typed Profile
```

---

## 4. Entities & Enums

### `lib/domain/entities/enums.dart`
Key enums relevant to the latest work:

| Enum | Values |
|---|---|
| `PaymentMethod` | `cash`, `card`, `bankTransfer`, `stripe`, `writtenOff`, `none` |
| `PaymentType` | `membership`, `payt`, `other` |
| `PaytPaymentStatus` | `pending`, `paid`, `writtenOff` |
| `MembershipStatus` | `active`, `trial`, `lapsed`, `expired`, `cancelled`, `pendingRenewal` |
| `MembershipPlanType` | `monthly`, `termly`, `annual`, `payAsYouTrain`, `trial`, `complimentary` |
| `ProfileType` | `adultStudent`, `juniorStudent`, `coach`, `parentGuardian` |
| `RankType` | `kyu`, `dan`, `mon`, `ungraded` |
| `CheckInMethod` | `selfCheckIn`, `adminMarkAttendance`, `queueResolution` |

**All switches over enums must be exhaustive.** When adding a new enum value, grep for every switch on that enum and add the new case.

### `lib/domain/entities/profile.dart`
Full GDPR fields: `isAnonymised`, `anonymisedAt`, `dataProcessingConsent`, `dataProcessingConsentDate`, `dataProcessingConsentVersion`.
Family link fields: `parentProfileId`, `secondParentProfileId`, `payingParentId`.
Computed getters: `fullName`, `isJunior`, `isAdult`, `isCoach`, `isParentGuardian`.

### `lib/domain/entities/cash_payment.dart`
```dart
class CashPayment extends Equatable {
  final String id;
  final String profileId;
  final double amount;
  final PaymentMethod paymentMethod;
  final PaymentType paymentType;       // membership | payt | other
  final DateTime recordedAt;
  final String recordedByAdminId;
  final String? membershipId;          // set for PaymentType.membership
  final String? paytSessionId;         // set for PaymentType.payt
  final String? notes;
  final String? editedByAdminId;       // set on edit (super-admin only)
  final DateTime? editedAt;
}
```

### `lib/domain/entities/payt_session.dart`
```dart
class PaytSession extends Equatable {
  final String id;
  final String profileId;
  final String disciplineId;
  final String? attendanceRecordId;
  final DateTime sessionDate;
  final double amount;                 // price snapshot at time of check-in
  final PaytPaymentStatus paymentStatus; // pending | paid | writtenOff
  final PaymentMethod paymentMethod;
  final DateTime? paidAt;
  final String? paidByAdminId;
  final String? writtenOffByAdminId;
  final DateTime? writtenOffAt;
  final String? writeOffReason;
}
```

---

## 5. Repository Interfaces

All in `lib/domain/repositories/`. Key additions from Payments build:

### `cash_payment_repository.dart`
```dart
abstract interface class CashPaymentRepository {
  Future<String> create(CashPayment payment);
  Future<void> edit(String id, {
    required double amount,
    required PaymentMethod paymentMethod,
    required PaymentType paymentType,
    String? notes,
    required String editedByAdminId,
  });
  Stream<List<CashPayment>> watchAll();
  Stream<List<CashPayment>> watchForProfile(String profileId);
  Stream<List<CashPayment>> watchForMembership(String membershipId);
}
```

### `payt_session_repository.dart`
```dart
abstract interface class PaytSessionRepository {
  Future<String> create(PaytSession session);
  Future<void> markPaid(String id, {
    required PaymentMethod paymentMethod,
    required String paidByAdminId,
  });
  Future<void> writeOff(String id, {
    required String writtenOffByAdminId,
    required String writeOffReason,
  });
  Stream<List<PaytSession>> watchAll();
  Stream<List<PaytSession>> watchForProfile(String profileId);
  Stream<List<PaytSession>> watchPendingForProfile(String profileId);
}
```

---

## 6. Providers

### `lib/core/providers/repository_providers.dart`
All repository providers. Always use these — never instantiate repositories directly.

### `lib/core/providers/payments_providers.dart` ← NEW (Payments build)
```dart
// Auth stub — replace when real auth session implemented
final isSuperAdminProvider = Provider<bool>((ref) => false); // TODO(auth-session)

// Use case providers
resolvePaytSessionUseCaseProvider
bulkResolvePaytSessionsUseCaseProvider
writeOffPaytSessionUseCaseProvider
recordStandalonePaymentUseCaseProvider
editPaymentUseCaseProvider          // super-admin only

// Stream providers
allPaytSessionsProvider              // StreamProvider<List<PaytSession>>
paytSessionsForProfileProvider       // StreamProvider.family<List<PaytSession>, String>
pendingPaytSessionsForProfileProvider// StreamProvider.family<List<PaytSession>, String>
allCashPaymentsProvider              // StreamProvider<List<CashPayment>>
cashPaymentsForProfileProvider       // StreamProvider.family<List<CashPayment>, String>
cashPaymentsForMembershipProvider    // StreamProvider.family<List<CashPayment>, String>

// Derived providers
outstandingBalanceProvider           // Provider.family<double, String> (sum pending PaytSessions)
pendingPaytSessionCountProvider      // Provider.family<int, String>
```

### `lib/core/providers/profile_providers.dart`
`profileListProvider`, `profilesByTypeProvider`, `profileProvider(id)`, `profileFormNotifierProvider`, plus use-case providers.

### `lib/core/providers/discipline_providers.dart`
`disciplineListProvider`, `activeDisciplineListProvider`, `disciplineProvider(id)`, `rankListProvider(disciplineId)`, form notifiers.

### `lib/core/providers/attendance_providers.dart`
All attendance use-case providers. Note: `createAttendanceSessionUseCaseProvider`, `markAttendanceUseCaseProvider`, and `selfCheckInUseCaseProvider` all inject `membershipRepositoryProvider` and `paytSessionRepositoryProvider` for PAYT auto-creation.

### `lib/core/providers/membership_providers.dart`
All membership use-case providers and stream providers including `membershipsByStatusProvider`.

### `lib/core/providers/grading_providers.dart`
All grading use-case providers and stream providers.

### `lib/core/providers/enrollment_providers.dart`
All enrollment use-case providers.

---

## 7. Use Cases — Payments

All in `lib/domain/use_cases/payments/`:

| File | What it does |
|---|---|
| `resolve_payt_session_use_case.dart` | Marks a PaytSession paid + creates CashPayment(type: payt) |
| `bulk_resolve_payt_sessions_use_case.dart` | Loops `ResolvePaytSessionUseCase` for a list of sessions |
| `write_off_payt_session_use_case.dart` | Calls `paytRepo.writeOff` — no CashPayment written |
| `record_standalone_payment_use_case.dart` | Creates CashPayment(type: other) with no linked entity |
| `edit_payment_use_case.dart` | Calls `cashRepo.edit` — super-admin only |

---

## 8. PAYT Auto-Creation (Attendance Integration)

When a student with an active PAYT membership attends a session, a pending `PaytSession` is automatically created. This happens in **three places**:

1. **`self_check_in_use_case.dart`** — student self check-in via kiosk
2. **`mark_attendance_use_case.dart`** — coach marks attendance in admin app
3. **`create_attendance_session_use_case.dart`** — queue resolution during session close

All three use cases now accept `MembershipRepository` and `PaytSessionRepository` in their constructors. After creating an `AttendanceRecord`, they:
1. Call `membershipRepo.getActiveForProfile(studentId)` to find the active membership
2. Check `membership.isPayAsYouTrain`
3. If true, create a `PaytSession` with `amount: membership.monthlyAmount` (price snapshot) and link `attendanceRecordId`

---

## 9. Routing

`lib/core/router/app_router.dart` — two separate GoRouter instances.
Route name constants are in `lib/core/router/route_names.dart`. Always use named routes.

### Admin router

```
/admin/login            → AdminLoginScreen
/admin/dashboard        → _PlaceholderScreen ⚠️
/admin/profiles         → ProfileListScreen
  /admin/profiles/create
  /admin/profiles/:id   → ProfileDetailScreen (3 tabs: Info | Memberships | Payments)
    /admin/profiles/:id/edit
/admin/disciplines      → DisciplineListScreen
  /admin/disciplines/create
  /admin/disciplines/:disciplineId → DisciplineDetailScreen
    /admin/disciplines/:disciplineId/edit
    /admin/disciplines/:disciplineId/ranks/create
    /admin/disciplines/:disciplineId/ranks/:rankId/edit
/admin/enrollment       → EnrollmentListScreen ✅
/admin/attendance       → AttendanceListScreen ✅
  /admin/attendance/create
  /admin/attendance/:sessionId
/admin/grading          → GradingListScreen ✅
  /admin/grading/create
  /admin/grading/:eventId
/admin/memberships      → MembershipListScreen ✅
  /admin/memberships/create  (wizard)
  /admin/memberships/:id
/admin/payments         → PaymentsListScreen ✅
  /admin/payments/record      ← LITERAL before :paymentId
  /admin/payments/report      ← LITERAL before :paymentId
  /admin/payments/bulk-resolve/:profileId
  /admin/payments/:paymentId  → PaymentDetailScreen
/admin/settings         → _PlaceholderScreen ⚠️
/admin/notifications    → _PlaceholderScreen ⚠️
```

**Important:** Literal sub-routes (`record`, `report`) are registered **before** the parameterised `:paymentId` route to prevent go_router treating them as path params.

### Student router

```
/student/select         → StudentSelectScreen
/student/pin            → PinEntryScreen
/student/home           → StudentHomeScreen ✅
/student/checkin        → SelfCheckInScreen ✅
/student/grades         → StudentGradesScreen ✅
/student/attendance     → _PlaceholderScreen ⚠️
/student/profile        → StudentProfileScreen
```

---

## 10. What Is Fully Built

| Feature | Screens | Domain | Data |
|---|---|---|---|
| Admin Firebase auth | ✅ | ✅ | ✅ |
| Student PIN session auth | ✅ | ✅ | ✅ |
| Database seeder | — | — | ✅ |
| Profiles (CRUD, GDPR consent, anonymisation) | ✅ | ✅ | ✅ |
| Disciplines (list, create, edit, detail) | ✅ | ✅ | ✅ |
| Ranks (create, edit, delete, reorder drag) | ✅ | ✅ | ✅ |
| App settings (read-only) | — | ✅ | ✅ |
| Enrollment | ✅ | ✅ | ✅ |
| Memberships (create wizard, detail, renew, cancel, PAYT) | ✅ | ✅ | ✅ |
| Attendance (sessions, mark, self check-in, queue) | ✅ | ✅ | ✅ |
| Grading (events, nominate, results, student grades view) | ✅ | ✅ | ✅ |
| Payments (list, detail, PAYT resolve, bulk resolve, record, report) | ✅ | ✅ | ✅ |
| Student home | ✅ | — | — |
| Student self check-in | ✅ | ✅ | ✅ |
| Student grades view | ✅ | — | — |

---

## 11. What Is NOT Built Yet

Routes still pointing to `_PlaceholderScreen`:
- `/admin/dashboard`
- `/admin/settings`
- `/admin/notifications`
- `/student/attendance` (student's own attendance history)

See `G:\Ichiban app\Ichiban App\Deferred features.md` for the full deferred items list with implementation context. **Read that file at the start of every session.**

---

## 12. Active TODO Stubs — Auth Session

Throughout the codebase, admin IDs are hardcoded pending real auth integration. Search for `TODO(auth-session)` to find all of them:

| File | Hardcoded value | What it should be |
|---|---|---|
| `record_payment_screen.dart` | `'admin'` | Current admin's UID from auth session |
| `bulk_resolve_screen.dart` | `'admin'` | Current admin's UID |
| `payment_detail_screen.dart` | `'superadmin'` | Current super-admin's UID |
| `payments_providers.dart` | `isSuperAdminProvider` returns `false` | Read from auth session claims |
| Multiple attendance screens | `'admin'` | Current admin's UID |
| Multiple grading screens | `'admin'` | Current admin's UID |

When the auth/session feature is built, replace all `TODO(auth-session)` occurrences with reads from the auth provider.

---

## 13. Coding Patterns

### Sentinel copyWith for nullable fields
Standard `copyWith` cannot distinguish "clear to null" from "omit (keep existing)". For nullable int/string fields in entities and form states:

```dart
const _absent = Object();

MyEntity copyWith({Object? someNullableField = _absent}) => MyEntity(
  someNullableField: identical(someNullableField, _absent)
      ? this.someNullableField
      : someNullableField as int?,
);
```

Used on `Rank.monCount`, `Rank.minAttendanceForGrading`, and their form state equivalents.

### Exhaustive switches
All `switch` expressions over enums must cover every value. When you add a new enum value, run `flutter analyze` and fix every non-exhaustive switch.

When `PaymentMethod.writtenOff` was added it required fixes in:
- `create_membership_wizard_screen.dart`
- `membership_detail_screen.dart` (two switches)

### `DropdownButtonFormField` — use `initialValue`, not `value`
Flutter 3.33.0+ deprecates `value:` on `FormField` subclasses. Always use `initialValue:`.

### `outstandingBalanceProvider` fold type
When folding a stream of doubles, always provide an explicit type parameter to avoid nullable inference:
```dart
sessions.fold<double>(0.0, (sum, s) => sum + s.amount)
```

### Router sub-route ordering
In go_router, literal path segments must be declared before parameterised ones:
```dart
GoRoute(path: 'record', ...),    // BEFORE
GoRoute(path: 'report', ...),    // BEFORE
GoRoute(path: ':paymentId', ...) // AFTER
```

---

## 14. Tests

28 passing unit tests in `test/providers/`. Run with:
```
cd "G:\Ichiban app\Ichiban App\.claude\worktrees\confident-driscoll"
flutter test
```

---

## 15. Support Files

| File | Purpose |
|---|---|
| `G:\Ichiban app\Ichiban App\.claude\worktrees\confident-driscoll\Deferred features.md` | All deferred items with context to build them cold. Read on every session start. Delete when built. |
| `G:\Ichiban app\Ichiban App\testing notes\testing_notes.md` | Checklist of all test cases for every built feature. Append after every feature build. |
| `C:\Users\kiero\.claude\projects\G--Ichiban-app-Ichiban-App\memory\MEMORY.md` | Persistent memory rules for this project. |

---

## 16. Working Protocol

1. **Before any work:** Read `Deferred features.md`. If any item can be built as part of the current handover, build it first, then delete it from the file.
2. **Present a plan and wait for approval before writing any code.**
3. **After any feature:** Append test cases to `testing notes/testing_notes.md`.
4. **When discovering something deferred:** Add to `Deferred features.md` immediately with enough context to act cold.
5. **When a deferred item is built:** Delete the entry from `Deferred features.md` — do not mark as done, DELETE it.
6. **Commits:** Only commit when explicitly asked. Never `--no-verify`.
7. Work strictly in the worktree path; never edit main project root.
8. Clean Architecture — no Firebase imports in domain, no business logic in screens.
9. Use `withConverter` pattern — all Firestore access goes through `FirestoreCollections`.
10. Use `NotifierProvider.autoDispose` for all form state.
11. Screens use `AsyncValue.when(loading, error, data)` — never `.value!`.
12. Show errors in `SnackBar`, not crashes or bare `print`.

---

## 17. Known Issues / Gotchas

- **Bundle ID is temporary:** `com.ichibanapp` — update Android/iOS/Firebase once trading name confirmed.
- **Student PIN with null `pinHash`:** Behaviour is undefined when a profile has no PIN set. Tracked in `Deferred features.md` item 6.
- **`isSuperAdminProvider` stub:** Currently hard-wired to `false`. The Edit button on `PaymentDetailScreen` will never appear until this is wired to real auth claims.
- **Firebase not initialised in tests:** `Firebase.initializeApp()` is commented out in test files. Firestore-dependent providers are tested via mocks only.
- **PAYT session amount is a price snapshot:** `membership.monthlyAmount` is copied at check-in time. If the membership price changes later, existing pending sessions keep the original amount.
- **Write-off has no CashPayment:** A written-off PAYT session produces no `CashPayment` audit record — only the `PaytSession` status field changes. This is by design.
