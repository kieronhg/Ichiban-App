import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers/auth_providers.dart';
import '../../core/providers/student_session_provider.dart';
import '../../domain/entities/profile.dart';
import '../../presentation/features/auth/admin_login_screen.dart';
import '../../presentation/features/auth/student_select_screen.dart';
import '../../presentation/features/auth/pin_entry_screen.dart';
import '../../presentation/features/profiles/profile_detail_screen.dart';
import '../../presentation/features/profiles/profile_form_screen.dart';
import '../../presentation/features/profiles/profile_list_screen.dart';
import '../../presentation/features/profiles/student_profile_screen.dart';
import '../../presentation/features/disciplines/discipline_list_screen.dart';
import '../../presentation/features/disciplines/discipline_detail_screen.dart';
import '../../presentation/features/disciplines/discipline_form_screen.dart';
import '../../presentation/features/disciplines/rank_form_screen.dart';
import '../../presentation/features/enrollment/enrol_discipline_screen.dart';
import '../../presentation/features/enrollment/bulk_enrol_upload_screen.dart';
import '../../presentation/features/enrollment/bulk_enrol_preview_screen.dart';
import '../../presentation/features/enrollment/csv_enrolment_parser.dart';
import '../../domain/entities/discipline.dart';
import '../../domain/entities/rank.dart';
import 'route_names.dart';

// Placeholder screens — replaced during feature implementation phases
class _PlaceholderScreen extends StatelessWidget {
  final String label;
  const _PlaceholderScreen(this.label);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(label)),
      body: Center(
        child: Text(label, style: Theme.of(context).textTheme.headlineMedium),
      ),
    );
  }
}

class AppRouter {
  AppRouter._();

  // ── Admin router ───────────────────────────────────────────────────────

  static GoRouter adminRouter({required WidgetRef ref}) => GoRouter(
    initialLocation: RouteNames.adminDashboard,
    redirect: (context, state) {
      final isAuthenticated = ref.read(isAdminAuthenticatedProvider);
      final isAuthLoading = ref.read(authStateProvider).isLoading;
      final onLoginPage = state.matchedLocation == RouteNames.adminLogin;

      // Still resolving auth state — don't redirect yet
      if (isAuthLoading) return null;

      // Not authenticated → send to login (unless already there)
      if (!isAuthenticated && !onLoginPage) {
        return RouteNames.adminLogin;
      }

      // Authenticated + on login page → send to dashboard
      if (isAuthenticated && onLoginPage) {
        return RouteNames.adminDashboard;
      }

      return null;
    },
    refreshListenable: _AuthChangeNotifier(ref),
    routes: [
      GoRoute(
        path: RouteNames.adminLogin,
        name: 'adminLogin',
        builder: (_, state) => const AdminLoginScreen(),
      ),
      GoRoute(
        path: RouteNames.adminDashboard,
        name: 'adminDashboard',
        builder: (_, state) => const _PlaceholderScreen('Dashboard'),
      ),

      // ── Profiles ──────────────────────────────────────────────
      GoRoute(
        path: RouteNames.adminProfiles,
        name: 'adminProfiles',
        builder: (_, state) => const ProfileListScreen(),
        routes: [
          GoRoute(
            path: 'create',
            name: 'adminProfileCreate',
            builder: (_, state) => const ProfileFormScreen(),
          ),
          GoRoute(
            path: ':id',
            name: 'adminProfileDetail',
            builder: (_, state) =>
                ProfileDetailScreen(profileId: state.pathParameters['id']!),
            routes: [
              GoRoute(
                path: 'edit',
                name: 'adminProfileEdit',
                builder: (_, state) =>
                    ProfileFormScreen(existingProfile: state.extra as Profile?),
              ),
              GoRoute(
                path: 'enrol',
                name: 'adminProfileEnrol',
                builder: (_, state) =>
                    EnrolDisciplineScreen(profile: state.extra as Profile),
              ),
            ],
          ),
        ],
      ),

      // ── Disciplines & Ranks ────────────────────────────────────
      GoRoute(
        path: RouteNames.adminDisciplines,
        name: 'adminDisciplines',
        builder: (_, state) => const DisciplineListScreen(),
        routes: [
          GoRoute(
            path: 'create',
            name: 'adminDisciplineCreate',
            builder: (_, state) => const DisciplineFormScreen(),
          ),
          GoRoute(
            path: ':disciplineId',
            name: 'adminDisciplineDetail',
            builder: (_, state) => DisciplineDetailScreen(
              disciplineId: state.pathParameters['disciplineId']!,
            ),
            routes: [
              GoRoute(
                path: 'edit',
                name: 'adminDisciplineEdit',
                builder: (_, state) => DisciplineFormScreen(
                  existingDiscipline: state.extra as Discipline?,
                ),
              ),
              GoRoute(
                path: 'ranks/create',
                name: 'adminRankCreate',
                builder: (_, state) => RankFormScreen(
                  disciplineId: state.pathParameters['disciplineId']!,
                  nextDisplayOrder: (state.extra as int?) ?? 0,
                ),
              ),
              GoRoute(
                path: 'ranks/:rankId/edit',
                name: 'adminRankEdit',
                builder: (_, state) => RankFormScreen(
                  disciplineId: state.pathParameters['disciplineId']!,
                  existingRank: state.extra as Rank?,
                ),
              ),
              GoRoute(
                path: 'bulk-enrol',
                name: 'adminDisciplineBulkEnrol',
                builder: (_, state) => BulkEnrolUploadScreen(
                  preselectedDisciplineId: state.pathParameters['disciplineId'],
                ),
              ),
            ],
          ),
        ],
      ),
      // ── Enrollment (top-level bulk enrol entry point) ──────────
      GoRoute(
        path: RouteNames.adminEnrollment,
        name: 'adminEnrollment',
        builder: (_, state) => const BulkEnrolUploadScreen(),
      ),
      GoRoute(
        path: RouteNames.adminBulkEnrolPreview,
        name: 'adminBulkEnrolPreview',
        builder: (_, state) =>
            BulkEnrolPreviewScreen(result: state.extra as CsvParseResult),
      ),
      GoRoute(
        path: RouteNames.adminAttendance,
        name: 'adminAttendance',
        builder: (_, state) => const _PlaceholderScreen('Attendance'),
      ),
      GoRoute(
        path: RouteNames.adminGrading,
        name: 'adminGrading',
        builder: (_, state) => const _PlaceholderScreen('Grading'),
      ),
      GoRoute(
        path: RouteNames.adminMemberships,
        name: 'adminMemberships',
        builder: (_, state) => const _PlaceholderScreen('Memberships'),
      ),
      GoRoute(
        path: RouteNames.adminPayments,
        name: 'adminPayments',
        builder: (_, state) => const _PlaceholderScreen('Payments'),
      ),
      GoRoute(
        path: RouteNames.adminSettings,
        name: 'adminSettings',
        builder: (_, state) => const _PlaceholderScreen('Settings'),
      ),
    ],
  );

  // ── Student router ─────────────────────────────────────────────────────

  static GoRouter studentRouter({required WidgetRef ref}) => GoRouter(
    initialLocation: RouteNames.studentSelect,
    redirect: (context, state) {
      final session = ref.read(studentSessionProvider);
      final location = state.matchedLocation;

      final onSelect = location == RouteNames.studentSelect;
      final onPin = location == RouteNames.studentPin;

      if (!session.isProfileSelected) {
        // No profile picked — must go to select screen
        return onSelect ? null : RouteNames.studentSelect;
      }

      if (!session.isAuthenticated) {
        // Profile selected but PIN not yet entered
        return onPin ? null : RouteNames.studentPin;
      }

      // Fully authenticated — don't let them go back to select/pin
      if (onSelect || onPin) return RouteNames.studentHome;

      return null;
    },
    refreshListenable: _StudentSessionChangeNotifier(ref),
    routes: [
      GoRoute(
        path: RouteNames.studentSelect,
        name: 'studentSelect',
        builder: (_, state) => const StudentSelectScreen(),
      ),
      GoRoute(
        path: RouteNames.studentPin,
        name: 'studentPin',
        builder: (_, state) => const PinEntryScreen(),
      ),
      GoRoute(
        path: RouteNames.studentHome,
        name: 'studentHome',
        builder: (_, state) => const _PlaceholderScreen('Student Home'),
      ),
      GoRoute(
        path: RouteNames.studentAttendance,
        name: 'studentAttendance',
        builder: (_, state) => const _PlaceholderScreen('My Attendance'),
      ),
      GoRoute(
        path: RouteNames.studentGrades,
        name: 'studentGrades',
        builder: (_, state) => const _PlaceholderScreen('My Grades'),
      ),
      GoRoute(
        path: RouteNames.studentProfile,
        name: 'studentProfile',
        builder: (_, state) => StudentProfileScreen(
          // Profile ID comes from the active session, not the route
          profileId: ref.read(studentSessionProvider).profileId ?? '',
        ),
      ),
    ],
  );
}

// ── Riverpod → Listenable bridges ─────────────────────────────────────────

/// Notifies go_router's [refreshListenable] whenever Firebase auth state
/// changes, triggering re-evaluation of the admin router's redirect.
class _AuthChangeNotifier extends ChangeNotifier {
  _AuthChangeNotifier(WidgetRef ref) {
    ref.listen(authStateProvider, (prev, next) => notifyListeners());
  }
}

/// Notifies go_router's [refreshListenable] whenever the student session
/// changes, triggering re-evaluation of the student router's redirect.
class _StudentSessionChangeNotifier extends ChangeNotifier {
  _StudentSessionChangeNotifier(WidgetRef ref) {
    ref.listen(studentSessionProvider, (prev, next) => notifyListeners());
  }
}
