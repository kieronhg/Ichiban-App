# Ichiban App — Full Project Handover

**Date produced:** 19 April 2026  
**Purpose:** Complete context for a new Claude chat session to continue development without any prior conversation history.

---

## 1. Project Overview

**Ichiban** is a dojo management application for a martial arts club. It is built in Flutter and targets two separate app flavors:

| Flavor | Entry point | Purpose |
|---|---|---|
| **admin** | `lib/main_admin.dart` | Club administrators manage profiles, memberships, disciplines, grading, attendance, payments |
| **student** | `lib/main_student.dart` | Students view their own profile, attendance, and grades |

**Tech stack:**
- Flutter / Dart (SDK ^3.11.4)
- Firebase (Auth, Firestore, Cloud Messaging)
- Riverpod 3 for state management (`flutter_riverpod: ^3.1.0`)
- go_router 17 for navigation
- equatable for entity equality
- intl for date formatting
- crypto for PIN hashing
- flutter_stripe + pay for payments (data layer only — UI not yet built)

**Git worktree (active branch):**
`G:\Ichiban app\Ichiban App\.claude\worktrees\confident-driscoll\`  
Branch: `claude/confident-driscoll`

All work should be done in the worktree path above, not the main project root.

---

## 2. Architecture

The project follows **Clean Architecture** with three layers:

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
└── disciplines/
```

---

## 3. Firestore Collections

All collection names are defined in `lib/core/constants/app_constants.dart`.

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
| `gradingRecords` | `colGradingRecords` | `GradingRecord` |
| `attendanceSessions` | `colAttendanceSessions` | `AttendanceSession` |
| `attendanceRecords` | `colAttendanceRecords` | `AttendanceRecord` |
| `notificationLogs` | `colNotificationLogs` | `NotificationLog` |
| `emailTemplates` | `colEmailTemplates` | `EmailTemplate` |
| `appSettings` | `colAppSettings` | `AppSetting` |

**Pattern:** All collections use `withConverter` via `FirestoreCollections` — repositories never call `.data()` manually.

```dart
// Example usage in a repository
final snap = await FirestoreCollections.profiles().doc(id).get();
final profile = snap.data(); // already a typed Profile
```

---

## 4. Entities

### Profile (`lib/domain/entities/profile.dart`)
All fields — including the complete list of GDPR fields (`isAnonymised`, `anonymisedAt`, `dataProcessingConsent`, `dataProcessingConsentDate`, `dataProcessingConsentVersion`) and family link fields (`parentProfileId`, `secondParentProfileId`, `payingParentId`).

Key computed getters: `fullName`, `isJunior`, `isAdult`, `isCoach`, `isParentGuardian`.

### Discipline (`lib/domain/entities/discipline.dart`)
`id`, `name`, `description?`, `isActive`, `createdByAdminId`, `createdAt`

### Rank (`lib/domain/entities/rank.dart`)
`id`, `disciplineId`, `name`, `displayOrder`, `colourHex?`, `rankType` (enum), `monCount?`, `minAttendanceForGrading?`, `createdAt`

### Enums (`lib/domain/entities/enums.dart`)
`RankType` (kyu, dan, mon, ungraded), `ProfileType` (adultStudent, juniorStudent, coach, parentGuardian), `MembershipPlanType`, `MembershipStatus`, `PaymentMethod`, `NotificationChannel`, `NotificationType`, `EmailDeliveryStatus`, `CheckInMethod`, `PaytPaymentStatus`, `FamilyPricingTier`

---

## 5. Repository Pattern

Each domain repository interface is in `lib/domain/repositories/`. The Firestore implementation is in `lib/data/repositories/`.

Providers are in `lib/core/providers/repository_providers.dart` — each returns the concrete Firestore class cast to the abstract interface.

```dart
final profileRepositoryProvider = Provider<ProfileRepository>(
  (ref) => FirestoreProfileRepository(),
);
```

---

## 6. Providers

### `lib/core/providers/repository_providers.dart`
All 14 repository providers. Always read/watch these through the domain interface — never instantiate repositories directly.

### `lib/core/providers/profile_providers.dart`
- `getProfilesUseCaseProvider`, `getProfileUseCaseProvider`, `createProfileUseCaseProvider`, `updateProfileUseCaseProvider`, `deactivateProfileUseCaseProvider`, `setPinUseCaseProvider`, `anonymiseProfileUseCaseProvider`
- `profileListProvider` — `StreamProvider<List<Profile>>` (all profiles live)
- `profilesByTypeProvider` — `StreamProvider.family<List<Profile>, ProfileType>`
- `profileProvider` — `StreamProvider.family<Profile?, String>` (single profile by ID)
- `profileFormNotifierProvider` — `NotifierProvider.autoDispose<ProfileFormNotifier, ProfileFormState>`

### `lib/core/providers/discipline_providers.dart`
- 9 use-case providers for disciplines and ranks
- `disciplineListProvider` — all disciplines (active + inactive), live
- `activeDisciplineListProvider` — active disciplines only, live
- `disciplineProvider` — `StreamProvider.family<Discipline?, String>` (filtered from disciplineListProvider stream)
- `rankListProvider` — `StreamProvider.family<List<Rank>, String>` (by disciplineId)
- `disciplineFormNotifierProvider` — autoDispose notifier for discipline create/edit form
- `rankFormNotifierProvider` — autoDispose notifier for rank create/edit form

### `lib/core/providers/app_settings_providers.dart`
- `privacyPolicyVersionProvider` — `FutureProvider<String>` reading from `appSettings/privacyPolicyVersion`

### `lib/core/providers/auth_providers.dart`
- `authRepositoryProvider`, `authStateProvider`, `isAdminAuthenticatedProvider`, `currentAdminProvider`

### `lib/core/providers/student_session_provider.dart`
- `studentSessionProvider` — `NotifierProvider<StudentSessionNotifier, StudentSession>`
- Session state: `profileId?`, `isProfileSelected`, `isAuthenticated`
- Call `selectProfile(id)` → then `authenticate(pinHash)` to log in
- Call `clearSession()` to sign out

---

## 7. Routing

`lib/core/router/app_router.dart` — two separate GoRouter instances.

### Admin router
- Auth guard: if not authenticated, redirect to `/admin/login`
- `/admin/login` → `AdminLoginScreen`
- `/admin/dashboard` → `_PlaceholderScreen` ⚠️
- `/admin/profiles` → `ProfileListScreen`
  - `/admin/profiles/create` → `ProfileFormScreen()`
  - `/admin/profiles/:id` → `ProfileDetailScreen(profileId)`
    - `/admin/profiles/:id/edit` → `ProfileFormScreen(existingProfile: extra)`
- `/admin/disciplines` → `DisciplineListScreen`
  - `/admin/disciplines/create` → `DisciplineFormScreen()`
  - `/admin/disciplines/:disciplineId` → `DisciplineDetailScreen`
    - `/admin/disciplines/:disciplineId/edit` → `DisciplineFormScreen(existingDiscipline: extra)`
    - `/admin/disciplines/:disciplineId/ranks/create` → `RankFormScreen(disciplineId, nextDisplayOrder: extra)`
    - `/admin/disciplines/:disciplineId/ranks/:rankId/edit` → `RankFormScreen(disciplineId, existingRank: extra)`
- `/admin/attendance`, `/admin/grading`, `/admin/memberships`, `/admin/payments`, `/admin/settings` → `_PlaceholderScreen` ⚠️

### Student router
- Session guard (3 states: no profile selected → `/student/select`, profile selected but not authed → `/student/pin`, authed → allow)
- `/student/select` → `StudentSelectScreen`
- `/student/pin` → `PinEntryScreen`
- `/student/home`, `/student/attendance`, `/student/grades` → `_PlaceholderScreen` ⚠️
- `/student/profile` → `StudentProfileScreen`

### Route names
All route names are in `lib/core/router/route_names.dart`. Always use named routes via `context.pushNamed('routeName')` or `context.goNamed('routeName')`.

---

## 8. Screen Patterns

### Admin screen pattern (ConsumerWidget)
```dart
class MyScreen extends ConsumerWidget {
  const MyScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listAsync = ref.watch(someListProvider);
    return listAsync.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(appBar: AppBar(), body: Center(child: Text('Error: $e'))),
      data: (items) => Scaffold(...),
    );
  }
}
```

### Form screen pattern (ConsumerStatefulWidget with NotifierProvider.autoDispose)
Forms use a `NotifierProvider.autoDispose` that holds mutable form state. The form calls setters on the notifier and triggers `save()` which calls the relevant use case. Errors are shown in a SnackBar.

### Navigation patterns
- Edit screens receive their entity via `state.extra as EntityType?`
- Detail screens receive their ID via `state.pathParameters['id']!`
- rank create receives `nextDisplayOrder` as `(state.extra as int?) ?? 0`

---

## 9. GDPR Implementation

### Data processing consent (create/edit form)
`lib/presentation/features/profiles/profile_form_screen.dart` contains a `_GdprConsentSection` widget:
- **Create mode:** A mandatory `CheckboxListTile`. The current `privacyPolicyVersion` is read from `appSettings` via `privacyPolicyVersionProvider` and stamped to `dataProcessingConsentVersion` when ticked. Save is blocked while unchecked.
- **Edit mode (consent given):** Green read-only banner showing policy version. No checkbox — directs admin to erasure process to withdraw consent.
- **Edit mode (consent not given):** Checkbox shown.

### Right to Erasure (manual, admin-triggered)
`lib/presentation/features/profiles/profile_detail_screen.dart`:
- 'Erase Personal Data' button visible when `!profile.isAnonymised`
- Two-step confirmation dialog (Step 1 lists what will be wiped, Step 2 final confirm)
- Calls `anonymiseProfileUseCaseProvider`

`lib/domain/use_cases/profile/anonymise_profile_use_case.dart`:
- Throws `ArgumentError` if ID empty
- Throws `StateError` if already anonymised
- Calls `repo.anonymise(id)`

`lib/data/repositories/firestore_profile_repository.dart` → `anonymise(id)`:
- Required String fields → `'[Anonymised]'` (keeps ProfileConverter working — never store empty/null for required strings)
- `dateOfBirth` → `Timestamp.fromDate(DateTime.utc(1970))`
- Nullable fields (`gender`, `addressLine2`, `allergiesOrMedicalNotes`, `pinHash`, `fcmToken`) → `null`
- Sets `isAnonymised: true`, `anonymisedAt: Timestamp.now()`

### Anonymised profile display
`profile_detail_screen.dart` hides personal/contact/emergency sections when `profile.isAnonymised`. Shows grey banner with date. Profile types, member-since, photo consent remain visible.

---

## 10. Nullable Int `copyWith` Sentinel Pattern

Standard Dart `copyWith` cannot distinguish "pass null to clear" from "omit to keep". For `Rank.monCount` and `Rank.minAttendanceForGrading` (and similarly in `RankFormState`):

```dart
const _absent = Object(); // module-private sentinel

RankFormState copyWith({
  Object? monCount = _absent,
  Object? minAttendanceForGrading = _absent,
  // ...
}) => RankFormState(
  monCount: monCount == _absent ? this.monCount : monCount as int?,
  // ...
);
```

---

## 11. What Is Fully Built

| Feature | Screens | Domain | Data |
|---|---|---|---|
| Auth (admin Firebase) | ✅ | ✅ | ✅ |
| Auth (student PIN session) | ✅ | ✅ | ✅ |
| Database seeder | — | — | ✅ |
| Profiles (CRUD, GDPR consent, anonymisation) | ✅ | ✅ | ✅ |
| Disciplines (list, create, edit, detail) | ✅ | ✅ | ✅ |
| Ranks (create, edit, delete, reorder drag) | ✅ | ✅ | ✅ |
| App settings (read-only from Firestore) | — | ✅ | ✅ |

**Data layer only built (entities + repos + converters), screens not yet built:**
Memberships, MembershipPricing, Enrollment, GradingRecord, AttendanceSessions, AttendanceRecords, CashPayments, PaytSessions, NotificationLogs, EmailTemplates

---

## 12. What Is NOT Built Yet (Placeholder Screens)

These routes exist in the router but point to `_PlaceholderScreen`:
- `/admin/dashboard`
- `/admin/attendance`
- `/admin/grading`
- `/admin/memberships`
- `/admin/payments`
- `/admin/settings`
- `/student/home`
- `/student/attendance`
- `/student/grades`

See `G:\Ichiban app\Ichiban App\Deferred features.md` for full deferred items list with context. **Always read that file when starting a new session.**

---

## 13. Support Files

| File | Purpose |
|---|---|
| `G:\Ichiban app\Ichiban App\testing notes\testing_notes.md` | Checklist of all test cases for every built feature. Add new items after every feature. |
| `G:\Ichiban app\Ichiban App\Deferred features.md` | All deferred items with enough context to build them cold. **Read on every session start. Delete items when built. Add items when discovered.** |
| `C:\Users\kiero\.claude\projects\G--Ichiban-app-Ichiban-App\memory\MEMORY.md` | Persistent memory rules for this project. |

---

## 14. Working Protocol

1. **Before any work:** Read `Deferred features.md`. If any item can be built as part of the current handover, build it first, then delete it from the file.
2. **After any feature:** Add test cases to `testing notes/testing_notes.md`.
3. **When discovering something that can't be built now:** Add it to `Deferred features.md` immediately with enough context to act cold.
4. **When building a deferred item:** Delete it from `Deferred features.md` as soon as it is done — not "mark as done", DELETE the entry.
5. Always work in the worktree: `G:\Ichiban app\Ichiban App\.claude\worktrees\confident-driscoll\`
6. Follow clean architecture strictly — no Firebase imports in domain layer, no business logic in screens.
7. Use the `withConverter` pattern — all Firestore access goes through `FirestoreCollections`.
8. Use `NotifierProvider.autoDispose` for all form state.
9. Screens use `AsyncValue.when(loading, error, data)` — never `.value!`.
10. Show errors in `SnackBar`, not crashes or bare `print`.

---

## 15. Key Known Issues / Gotchas

- **Bundle ID is temporary:** `com.ichibanapp` — update Android/iOS/Firebase once trading name confirmed.
- **Rank delete has no guard:** `DeleteRankUseCase` has no check for students currently holding that rank. A guard must be added before production. This is tracked in `Deferred features.md`.
- **Student PIN with null pinHash:** Behaviour undefined when a profile has no PIN set. Tracked in `Deferred features.md`.
- **`createdByAdminId` on disciplines:** Will be an empty string if admin is somehow unauthenticated. Should not be reachable in practice due to router guard.
- **Anonymised profiles appear in profile list** as '[Anonymised] [Anonymised]' — whether to add a visual treatment or filter needs product owner input. Tracked in `Deferred features.md`.
