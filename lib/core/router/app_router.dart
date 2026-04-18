import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../domain/entities/profile.dart';
import '../../presentation/features/profiles/profile_detail_screen.dart';
import '../../presentation/features/profiles/profile_form_screen.dart';
import '../../presentation/features/profiles/profile_list_screen.dart';
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

  static GoRouter adminRouter() => GoRouter(
        initialLocation: RouteNames.adminDashboard,
        routes: [
          GoRoute(
            path: RouteNames.adminLogin,
            name: 'adminLogin',
            builder: (_, state) => const _PlaceholderScreen('Admin Login'),
          ),
          GoRoute(
            path: RouteNames.adminDashboard,
            name: 'adminDashboard',
            builder: (_, state) => const _PlaceholderScreen('Dashboard'),
          ),

          // ── Profiles ────────────────────────────────────────────────
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
                builder: (_, state) => ProfileDetailScreen(
                  profileId: state.pathParameters['id']!,
                ),
                routes: [
                  GoRoute(
                    path: 'edit',
                    name: 'adminProfileEdit',
                    builder: (_, state) => ProfileFormScreen(
                      existingProfile: state.extra as Profile?,
                    ),
                  ),
                ],
              ),
            ],
          ),

          // ── Other admin routes (placeholder) ────────────────────────
          GoRoute(
            path: RouteNames.adminDisciplines,
            name: 'adminDisciplines',
            builder: (_, state) => const _PlaceholderScreen('Disciplines'),
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

  static GoRouter studentRouter() => GoRouter(
        initialLocation: RouteNames.studentSelect,
        routes: [
          GoRoute(
            path: RouteNames.studentSelect,
            name: 'studentSelect',
            builder: (_, state) => const _PlaceholderScreen('Select Student'),
          ),
          GoRoute(
            path: RouteNames.studentPin,
            name: 'studentPin',
            builder: (_, state) => const _PlaceholderScreen('Enter PIN'),
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
        ],
      );
}
