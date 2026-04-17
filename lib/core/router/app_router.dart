import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
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
        initialLocation: RouteNames.adminLogin,
        routes: [
          GoRoute(
            path: RouteNames.adminLogin,
            name: 'adminLogin',
            builder: (_, __) => const _PlaceholderScreen('Admin Login'),
          ),
          GoRoute(
            path: RouteNames.adminDashboard,
            name: 'adminDashboard',
            builder: (_, __) => const _PlaceholderScreen('Dashboard'),
          ),
          GoRoute(
            path: RouteNames.adminProfiles,
            name: 'adminProfiles',
            builder: (_, __) => const _PlaceholderScreen('Profiles'),
          ),
          GoRoute(
            path: RouteNames.adminDisciplines,
            name: 'adminDisciplines',
            builder: (_, __) => const _PlaceholderScreen('Disciplines'),
          ),
          GoRoute(
            path: RouteNames.adminAttendance,
            name: 'adminAttendance',
            builder: (_, __) => const _PlaceholderScreen('Attendance'),
          ),
          GoRoute(
            path: RouteNames.adminGrading,
            name: 'adminGrading',
            builder: (_, __) => const _PlaceholderScreen('Grading'),
          ),
          GoRoute(
            path: RouteNames.adminMemberships,
            name: 'adminMemberships',
            builder: (_, __) => const _PlaceholderScreen('Memberships'),
          ),
          GoRoute(
            path: RouteNames.adminPayments,
            name: 'adminPayments',
            builder: (_, __) => const _PlaceholderScreen('Payments'),
          ),
          GoRoute(
            path: RouteNames.adminSettings,
            name: 'adminSettings',
            builder: (_, __) => const _PlaceholderScreen('Settings'),
          ),
        ],
      );

  static GoRouter studentRouter() => GoRouter(
        initialLocation: RouteNames.studentSelect,
        routes: [
          GoRoute(
            path: RouteNames.studentSelect,
            name: 'studentSelect',
            builder: (_, __) => const _PlaceholderScreen('Select Student'),
          ),
          GoRoute(
            path: RouteNames.studentPin,
            name: 'studentPin',
            builder: (_, __) => const _PlaceholderScreen('Enter PIN'),
          ),
          GoRoute(
            path: RouteNames.studentHome,
            name: 'studentHome',
            builder: (_, __) => const _PlaceholderScreen('Student Home'),
          ),
          GoRoute(
            path: RouteNames.studentAttendance,
            name: 'studentAttendance',
            builder: (_, __) => const _PlaceholderScreen('My Attendance'),
          ),
          GoRoute(
            path: RouteNames.studentGrades,
            name: 'studentGrades',
            builder: (_, __) => const _PlaceholderScreen('My Grades'),
          ),
        ],
      );
}
