import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers/admin_providers.dart';
import '../../core/providers/auth_providers.dart';
import '../../core/providers/student_session_provider.dart';
import '../../domain/entities/admin_user.dart';
import '../../domain/entities/attendance_session.dart';
import '../../domain/entities/email_template.dart';
import '../../domain/entities/notification_log.dart';
import '../../domain/entities/cash_payment.dart';
import '../../domain/entities/discipline.dart';
import '../../domain/entities/grading_event.dart';
import '../../domain/entities/grading_event_student.dart';
import '../../domain/entities/membership.dart';
import '../../domain/entities/profile.dart';
import '../../domain/entities/rank.dart';
import '../../presentation/features/attendance/attendance_list_screen.dart';
import '../../presentation/features/attendance/create_attendance_session_screen.dart';
import '../../presentation/features/attendance/queued_check_ins_screen.dart';
import '../../presentation/features/attendance/session_detail_screen.dart';
import '../../presentation/features/admin/admin_user_detail_screen.dart';
import '../../presentation/features/admin/admin_user_list_screen.dart';
import '../../presentation/features/admin/edit_admin_user_screen.dart';
import '../../presentation/features/admin/invite_coach_screen.dart';
import '../../presentation/features/auth/admin_login_screen.dart';
import '../../presentation/features/auth/entry_gateway_screen.dart';
import '../../presentation/features/auth/setup_wizard_screen.dart';
import '../../presentation/features/auth/pin_entry_screen.dart';
import '../../presentation/features/auth/student_select_screen.dart';
import '../../presentation/features/disciplines/discipline_detail_screen.dart';
import '../../presentation/features/disciplines/discipline_form_screen.dart';
import '../../presentation/features/disciplines/discipline_list_screen.dart';
import '../../presentation/features/disciplines/rank_form_screen.dart';
import '../../presentation/features/enrollment/bulk_enrol_preview_screen.dart';
import '../../presentation/features/enrollment/bulk_enrol_upload_screen.dart';
import '../../presentation/features/enrollment/csv_enrolment_parser.dart';
import '../../presentation/features/enrollment/enrol_discipline_screen.dart';
import '../../presentation/features/grading/create_grading_event_screen.dart';
import '../../presentation/features/grading/grading_event_detail_screen.dart';
import '../../presentation/features/grading/grading_list_screen.dart';
import '../../presentation/features/grading/nominate_students_screen.dart';
import '../../presentation/features/grading/record_results_screen.dart';
import '../../presentation/features/memberships/convert_membership_plan_screen.dart';
import '../../presentation/features/memberships/create_membership_wizard_screen.dart';
import '../../presentation/features/memberships/membership_detail_screen.dart';
import '../../presentation/features/memberships/membership_list_screen.dart';
import '../../presentation/features/memberships/renew_membership_screen.dart';
import '../../presentation/features/payments/bulk_resolve_screen.dart';
import '../../presentation/features/payments/financial_report_screen.dart';
import '../../presentation/features/payments/payment_detail_screen.dart';
import '../../presentation/features/payments/payments_list_screen.dart';
import '../../presentation/features/payments/record_payment_screen.dart';
import '../../presentation/features/notifications/admin_notification_detail_screen.dart';
import '../../presentation/features/notifications/student_notification_centre_screen.dart';
import '../../presentation/features/notifications/admin_notification_list_screen.dart';
import '../../presentation/features/notifications/email_template_editor_screen.dart';
import '../../presentation/features/notifications/email_template_list_screen.dart';
import '../../presentation/features/notifications/send_announcement_screen.dart';
import '../../presentation/features/profiles/profile_detail_screen.dart';
import '../../presentation/features/profiles/profile_form_screen.dart';
import '../../presentation/features/profiles/profile_list_screen.dart';
import '../../presentation/features/profiles/student_profile_screen.dart';
import '../../presentation/features/student/self_check_in_screen.dart';
import '../../presentation/features/student/student_grades_screen.dart';
import '../../presentation/features/student/student_home_screen.dart';
import 'route_names.dart';

class _PlaceholderScreen extends StatelessWidget {
  const _PlaceholderScreen(this.label);

  final String label;

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

  static GoRouter router({required WidgetRef ref}) => GoRouter(
    initialLocation: RouteNames.entry,
    redirect: (context, state) {
      final location = state.matchedLocation;
      final isEntryPage = location == RouteNames.entry;
      final isAdminRoute = location.startsWith('/admin');
      final isStudentRoute = location.startsWith('/student');

      final isAuthenticated = ref.read(isAdminAuthenticatedProvider);
      final isAuthLoading = ref.read(authStateProvider).isLoading;
      final isOnAdminLogin = location == RouteNames.adminLogin;
      final isOnAdminSetup = location == RouteNames.adminSetup;

      // Setup status — treat loading/error as "not complete" (show wizard).
      final setupAsync = ref.read(appSetupStatusProvider);
      final setupComplete = setupAsync.asData?.value.setupComplete ?? false;

      final session = ref.read(studentSessionProvider);
      final isOnStudentSelect = location == RouteNames.studentSelect;
      final isOnStudentPin = location == RouteNames.studentPin;

      // ── Setup wizard guard ─────────────────────────────────────────────
      // If setup is not done, the only admin page allowed is /admin/setup.
      if (!setupComplete && isAdminRoute && !isOnAdminSetup) {
        return RouteNames.adminSetup;
      }

      // Once setup is complete, prevent going back to wizard.
      if (setupComplete && isOnAdminSetup) {
        return isAuthenticated
            ? RouteNames.adminDashboard
            : RouteNames.adminLogin;
      }

      if (isAdminRoute) {
        if (isAuthLoading) return null;

        if (!isAuthenticated && !isOnAdminLogin && !isOnAdminSetup) {
          return RouteNames.adminLogin;
        }

        if (isAuthenticated && isOnAdminLogin) {
          return RouteNames.adminDashboard;
        }
      }

      if (isStudentRoute) {
        if (!session.isProfileSelected) {
          return isOnStudentSelect ? null : RouteNames.studentSelect;
        }

        if (!session.isAuthenticated) {
          return isOnStudentPin ? null : RouteNames.studentPin;
        }

        if (isOnStudentSelect || isOnStudentPin) {
          return RouteNames.studentHome;
        }
      }

      if (isEntryPage) {
        // If setup hasn't been completed yet, go to wizard.
        if (!setupComplete) {
          return RouteNames.adminSetup;
        }

        if (!isAuthLoading && isAuthenticated) {
          return RouteNames.adminDashboard;
        }

        if (session.isAuthenticated) {
          return RouteNames.studentHome;
        }
      }

      return null;
    },
    refreshListenable: _RouterRefreshNotifier(ref),
    routes: [
      GoRoute(
        path: RouteNames.entry,
        name: 'entry',
        builder: (_, state) => const EntryGatewayScreen(),
      ),
      GoRoute(
        path: RouteNames.adminSetup,
        name: 'adminSetup',
        builder: (_, state) => const SetupWizardScreen(),
      ),
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
        builder: (_, state) => const AttendanceListScreen(),
        routes: [
          GoRoute(
            path: 'create',
            name: 'adminAttendanceCreate',
            builder: (_, state) => const CreateAttendanceSessionScreen(),
          ),
          GoRoute(
            path: 'queued',
            name: 'adminAttendanceQueued',
            builder: (_, state) => const QueuedCheckInsScreen(),
          ),
          GoRoute(
            path: ':sessionId',
            name: 'adminAttendanceDetail',
            builder: (_, state) =>
                SessionDetailScreen(session: state.extra as AttendanceSession),
          ),
        ],
      ),
      GoRoute(
        path: RouteNames.adminGrading,
        name: 'adminGrading',
        builder: (_, state) => GradingListScreen(
          preFilterDisciplineId: state.extra is String
              ? state.extra as String
              : null,
        ),
        routes: [
          GoRoute(
            path: 'create',
            name: 'adminGradingCreate',
            builder: (_, state) => CreateGradingEventScreen(
              preselectedDisciplineId: state.extra is String
                  ? state.extra as String
                  : null,
            ),
          ),
          GoRoute(
            path: ':eventId',
            name: 'adminGradingDetail',
            builder: (_, state) =>
                GradingEventDetailScreen(event: state.extra as GradingEvent),
            routes: [
              GoRoute(
                path: 'nominate',
                name: 'adminGradingNominate',
                builder: (_, state) =>
                    NominateStudentsScreen(event: state.extra as GradingEvent),
              ),
              GoRoute(
                path: 'record-results',
                name: 'adminGradingRecordResults',
                builder: (_, state) {
                  final extra =
                      state.extra as (GradingEvent, GradingEventStudent);
                  return RecordResultsScreen(
                    event: extra.$1,
                    eventStudent: extra.$2,
                  );
                },
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: RouteNames.adminMemberships,
        name: 'adminMemberships',
        builder: (_, state) => const MembershipListScreen(),
        routes: [
          GoRoute(
            path: 'create',
            name: 'adminMembershipsCreate',
            builder: (_, state) => CreateMembershipWizardScreen(
              preselectedProfileId: state.extra is String
                  ? state.extra as String
                  : null,
            ),
          ),
          GoRoute(
            path: ':membershipId',
            name: 'adminMembershipsDetail',
            builder: (_, state) =>
                MembershipDetailScreen(membership: state.extra as Membership),
            routes: [
              GoRoute(
                path: 'renew',
                name: 'adminMembershipsRenew',
                builder: (_, state) => RenewMembershipScreen(
                  membership: state.extra as Membership,
                ),
              ),
              GoRoute(
                path: 'convert',
                name: 'adminMembershipsConvert',
                builder: (_, state) => ConvertMembershipPlanScreen(
                  membership: state.extra as Membership,
                ),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: RouteNames.adminPayments,
        name: 'adminPayments',
        builder: (_, state) => const PaymentsListScreen(),
        routes: [
          GoRoute(
            path: 'record',
            name: 'adminPaymentsRecord',
            builder: (_, state) => RecordPaymentScreen(
              preselectedProfileId: state.extra is String
                  ? state.extra as String
                  : null,
            ),
          ),
          GoRoute(
            path: 'report',
            name: 'adminPaymentsReport',
            builder: (_, state) => const FinancialReportScreen(),
          ),
          GoRoute(
            path: 'bulk-resolve/:profileId',
            name: 'adminPaymentsBulkResolve',
            builder: (_, state) => BulkResolveScreen(
              profileId: state.pathParameters['profileId']!,
            ),
          ),
          GoRoute(
            path: ':paymentId',
            name: 'adminPaymentsDetail',
            builder: (_, state) =>
                PaymentDetailScreen(payment: state.extra as CashPayment),
          ),
        ],
      ),
      GoRoute(
        path: RouteNames.adminTeam,
        name: 'adminTeam',
        builder: (_, state) => const AdminUserListScreen(),
        routes: [
          GoRoute(
            path: 'invite',
            name: 'adminTeamInvite',
            builder: (_, state) => const InviteCoachScreen(),
          ),
          GoRoute(
            path: ':uid',
            name: 'adminTeamDetail',
            builder: (_, state) =>
                AdminUserDetailScreen(uid: state.pathParameters['uid']!),
            routes: [
              GoRoute(
                path: 'edit',
                name: 'adminTeamEdit',
                builder: (_, state) =>
                    EditAdminUserScreen(adminUser: state.extra as AdminUser),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: RouteNames.adminNotifications,
        name: 'adminNotifications',
        builder: (_, state) => const AdminNotificationListScreen(),
        routes: [
          GoRoute(
            path: 'announce',
            name: 'adminSendAnnouncement',
            builder: (_, state) => const SendAnnouncementScreen(),
          ),
          GoRoute(
            path: 'templates',
            name: 'adminEmailTemplates',
            builder: (_, state) => const EmailTemplateListScreen(),
            routes: [
              GoRoute(
                path: ':templateKey',
                name: 'adminEmailTemplateEditor',
                builder: (_, state) => EmailTemplateEditorScreen(
                  template: state.extra as EmailTemplate,
                ),
              ),
            ],
          ),
          GoRoute(
            path: ':notificationId',
            name: 'adminNotificationDetail',
            builder: (_, state) => AdminNotificationDetailScreen(
              log: state.extra as NotificationLog,
            ),
          ),
        ],
      ),
      GoRoute(
        path: RouteNames.adminSettings,
        name: 'adminSettings',
        builder: (_, state) => const _PlaceholderScreen('Settings'),
      ),
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
        builder: (_, state) => const StudentHomeScreen(),
        routes: [
          GoRoute(
            path: 'checkin',
            name: 'studentCheckin',
            builder: (_, state) => const SelfCheckInScreen(),
          ),
        ],
      ),
      GoRoute(
        path: RouteNames.studentNotifications,
        name: 'studentNotifications',
        builder: (_, state) => const StudentNotificationCentreScreen(),
      ),
      GoRoute(
        path: RouteNames.studentAttendance,
        name: 'studentAttendance',
        builder: (_, state) => const _PlaceholderScreen('My Attendance'),
      ),
      GoRoute(
        path: RouteNames.studentGrades,
        name: 'studentGrades',
        builder: (_, state) => const StudentGradesScreen(),
      ),
      GoRoute(
        path: RouteNames.studentProfile,
        name: 'studentProfile',
        builder: (_, state) => StudentProfileScreen(
          profileId: ref.read(studentSessionProvider).profileId ?? '',
        ),
      ),
    ],
  );
}

class _RouterRefreshNotifier extends ChangeNotifier {
  _RouterRefreshNotifier(WidgetRef ref) {
    ref.listen(authStateProvider, (prev, next) => notifyListeners());
    ref.listen(studentSessionProvider, (prev, next) => notifyListeners());
    ref.listen(appSetupStatusProvider, (prev, next) => notifyListeners());
  }
}
