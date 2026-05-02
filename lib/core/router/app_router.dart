import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers/admin_providers.dart';
import '../../core/providers/admin_session_provider.dart';
import '../../core/providers/auth_providers.dart';
import '../../core/providers/kiosk_mode_provider.dart';
import '../../core/providers/student_auth_provider.dart';
import '../../core/providers/student_session_provider.dart';
import '../../domain/entities/enums.dart';
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
import '../../presentation/features/admin/owner_edit_coach_compliance_screen.dart';
import '../../presentation/features/coach/edit_dbs_details_screen.dart';
import '../../presentation/features/coach/edit_first_aid_details_screen.dart';
import '../../presentation/features/coach/edit_personal_details_screen.dart';
import '../../presentation/features/coach/my_profile_screen.dart';
import '../../presentation/features/dashboard/coach_dashboard_screen.dart';
import '../../presentation/features/dashboard/owner_dashboard_screen.dart';
import '../../presentation/features/auth/accept_invite_screen.dart';
import '../../presentation/features/auth/admin_login_screen.dart';
import '../../presentation/features/auth/entry_gateway_screen.dart';
import '../../presentation/features/auth/invite_expired_screen.dart';
import '../../presentation/features/auth/setup_wizard_screen.dart';
import '../../presentation/features/auth/pin_entry_screen.dart';
import '../../presentation/features/auth/student_select_screen.dart';
import '../../presentation/features/auth/student_email_verification_screen.dart';
import '../../presentation/features/auth/sign_up/student_sign_up_screen.dart';
import '../../presentation/features/student_portal/student_portal_account_screen.dart';
import '../../presentation/features/student_portal/student_portal_family_screen.dart';
import '../../presentation/features/student_portal/student_portal_grades_screen.dart';
import '../../presentation/features/student_portal/student_portal_home_screen.dart';
import '../../presentation/features/student_portal/student_portal_membership_screen.dart';
import '../../presentation/features/student_portal/student_portal_notifications_screen.dart';
import '../../presentation/features/student_portal/student_portal_schedule_screen.dart';
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
import '../../presentation/features/settings/danger_zone_screen.dart';
import '../../presentation/features/settings/email_templates_settings_screen.dart';
import '../../presentation/features/settings/gdpr_settings_screen.dart';
import '../../presentation/features/settings/general_settings_screen.dart';
import '../../presentation/features/settings/membership_pricing_screen.dart';
import '../../presentation/features/settings/notification_timings_screen.dart';
import '../../presentation/features/settings/settings_screen.dart';
import '../../presentation/features/student/self_check_in_screen.dart';
import '../../presentation/features/student/student_attendance_screen.dart';
import '../../presentation/features/student/student_grades_screen.dart';
import '../../presentation/features/student/student_home_screen.dart';
import 'route_names.dart';

class _DashboardScreen extends ConsumerWidget {
  const _DashboardScreen();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isCoach = ref.watch(isCoachProvider);
    return isCoach
        ? const CoachDashboardScreen()
        : const OwnerDashboardScreen();
  }
}

class AppRouter {
  AppRouter._();

  static GoRouter router({required WidgetRef ref}) => GoRouter(
    initialLocation: RouteNames.entry,
    redirect: (context, state) {
      final location = state.matchedLocation;

      // ── Kiosk mode overrides all routing ──────────────────────────────────
      final isKioskMode = ref.read(kioskModeProvider).isActive;
      // Kiosk routes live under /student — if kiosk is active and the user is
      // not already there, redirect them. Phase 5 will add a dedicated route.
      final isOnKioskRoute =
          location == RouteNames.studentSelect ||
          location == RouteNames.studentPin ||
          location == RouteNames.studentHome ||
          location == RouteNames.studentCheckin;
      if (isKioskMode && !isOnKioskRoute) {
        return RouteNames.studentSelect;
      }

      // ── Shared loading check ���─────────────────────────────────────────────
      final authState = ref.read(authStateProvider);
      final adminSession = ref.read(adminSessionProvider);
      final studentAuth = ref.read(studentAuthProvider);
      final isAnyLoading =
          authState.isLoading ||
          adminSession.isLoading ||
          studentAuth.isLoading;

      final isAdminAuthenticated = adminSession.isLoaded;
      final isStudentAuthenticated = studentAuth.isAuthenticated;

      final isEntryPage = location == RouteNames.entry;
      final isOnAdminLogin = location == RouteNames.adminLogin;
      final isOnAdminSetup = location == RouteNames.adminSetup;
      final isAdminRoute = location.startsWith('/admin');
      final isStudentPortalRoute = location.startsWith('/student-portal');
      // Kiosk routes start with /student but not /student-portal
      final isKioskRoute =
          location.startsWith('/student') && !isStudentPortalRoute;
      final isSignUpRoute = location == RouteNames.studentSignUp;

      // ── Admin routes ──────────────────────────────────────────────────────
      if (isAdminRoute) {
        if (isAnyLoading) return null;

        if (!isAdminAuthenticated && !isOnAdminLogin && !isOnAdminSetup) {
          return RouteNames.adminLogin;
        }

        if (isAdminAuthenticated && isOnAdminLogin) {
          return RouteNames.adminDashboard;
        }

        // My Profile is coach-only
        if (isAdminAuthenticated &&
            location.startsWith(RouteNames.adminMyProfile)) {
          final role = ref.read(currentAdminUserProvider)?.role;
          if (role == AdminRole.owner) return RouteNames.adminDashboard;
        }
      }

      // ── Student portal routes ───��─────────────────────────────────────────
      if (isStudentPortalRoute) {
        if (isAnyLoading) return null;
        if (!isStudentAuthenticated) return RouteNames.adminLogin;

        final isEmailVerified = studentAuth.isEmailVerified;
        final isOnVerifyEmail = location == RouteNames.studentPortalVerifyEmail;

        if (!isEmailVerified && !isOnVerifyEmail) {
          return RouteNames.studentPortalVerifyEmail;
        }
        if (isEmailVerified && isOnVerifyEmail) {
          return RouteNames.studentPortalHome;
        }
      }

      // ── Kiosk / legacy student routes (PIN-based check-in) ────────────────
      if (isKioskRoute) {
        final session = ref.read(studentSessionProvider);
        final isOnStudentSelect = location == RouteNames.studentSelect;
        final isOnStudentPin = location == RouteNames.studentPin;

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

      // ── Entry page ──────���─────────────────────────────────────────────────
      if (isEntryPage) {
        if (isAnyLoading) return null;
        if (isAdminAuthenticated) return RouteNames.adminDashboard;
        if (isStudentAuthenticated) {
          return studentAuth.isEmailVerified
              ? RouteNames.studentPortalHome
              : RouteNames.studentPortalVerifyEmail;
        }
        return RouteNames.adminLogin;
      }

      // ── Sign-up — accessible to unauthenticated users ─────────────────────
      if (isSignUpRoute) return null;

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
        builder: (_, state) => const _DashboardScreen(),
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
              GoRoute(
                path: 'compliance/edit',
                name: 'adminTeamComplianceEdit',
                builder: (_, state) => OwnerEditCoachComplianceScreen(
                  adminUserId: state.pathParameters['uid']!,
                  type: state.extra as CoachComplianceType,
                ),
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
        builder: (_, state) => const SettingsScreen(),
        routes: [
          GoRoute(
            path: 'general',
            name: 'adminSettingsGeneral',
            builder: (_, state) => const GeneralSettingsScreen(),
          ),
          GoRoute(
            path: 'pricing',
            name: 'adminSettingsPricing',
            builder: (_, state) => const MembershipPricingScreen(),
          ),
          GoRoute(
            path: 'notification-timings',
            name: 'adminSettingsNotifications',
            builder: (_, state) => const NotificationTimingsScreen(),
          ),
          GoRoute(
            path: 'gdpr',
            name: 'adminSettingsGdpr',
            builder: (_, state) => const GdprSettingsScreen(),
          ),
          GoRoute(
            path: 'email-templates',
            name: 'adminSettingsEmailTemplates',
            builder: (_, state) => const EmailTemplatesSettingsScreen(),
          ),
          GoRoute(
            path: 'danger-zone',
            name: 'adminSettingsDangerZone',
            builder: (_, state) => const DangerZoneScreen(),
          ),
        ],
      ),
      GoRoute(
        path: RouteNames.adminMyProfile,
        name: 'adminMyProfile',
        builder: (_, state) => const MyProfileScreen(),
        routes: [
          GoRoute(
            path: 'edit',
            name: 'coachMyProfileEdit',
            builder: (_, state) => const EditPersonalDetailsScreen(),
          ),
          GoRoute(
            path: 'dbs',
            name: 'coachMyProfileDbs',
            builder: (_, state) => const EditDbsDetailsScreen(),
          ),
          GoRoute(
            path: 'firstaid',
            name: 'coachMyProfileFirstAid',
            builder: (_, state) => const EditFirstAidDetailsScreen(),
          ),
        ],
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
        builder: (_, state) => const StudentAttendanceScreen(),
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

      // ── Student Portal (phone app) ────────────────────────────────────────
      GoRoute(
        path: RouteNames.studentPortalHome,
        name: 'studentPortalHome',
        builder: (_, state) => const StudentPortalHomeScreen(),
      ),
      GoRoute(
        path: RouteNames.studentPortalVerifyEmail,
        name: 'studentPortalVerifyEmail',
        builder: (_, state) => const StudentEmailVerificationScreen(),
      ),
      GoRoute(
        path: RouteNames.studentPortalGrades,
        name: 'studentPortalGrades',
        builder: (_, state) => const StudentPortalGradesScreen(),
      ),
      GoRoute(
        path: RouteNames.studentPortalMembership,
        name: 'studentPortalMembership',
        builder: (_, state) => const StudentPortalMembershipScreen(),
      ),
      GoRoute(
        path: RouteNames.studentPortalSchedule,
        name: 'studentPortalSchedule',
        builder: (_, state) => const StudentPortalScheduleScreen(),
      ),
      GoRoute(
        path: RouteNames.studentPortalNotifications,
        name: 'studentPortalNotifications',
        builder: (_, state) => const StudentPortalNotificationsScreen(),
      ),
      GoRoute(
        path: RouteNames.studentPortalFamily,
        name: 'studentPortalFamily',
        builder: (_, state) => const StudentPortalFamilyScreen(),
      ),
      GoRoute(
        path: RouteNames.studentPortalAccount,
        name: 'studentPortalAccount',
        builder: (_, state) => const StudentPortalAccountScreen(),
      ),

      // ── Sign-up wizard ────────────────────────────────────────────────────
      GoRoute(
        path: RouteNames.studentSignUp,
        name: 'studentSignUp',
        builder: (_, state) => const StudentSignUpScreen(),
      ),

      // ── Invite acceptance ──────────────────────────────────────────────────
      GoRoute(
        path: RouteNames.inviteAccept,
        name: 'inviteAccept',
        builder: (_, state) {
          final profileId =
              state.uri.queryParameters['profileId'] ?? '';
          return AcceptInviteScreen(profileId: profileId);
        },
      ),
      GoRoute(
        path: RouteNames.inviteExpired,
        name: 'inviteExpired',
        builder: (_, state) {
          final profileId = state.uri.queryParameters['profileId'];
          return InviteExpiredScreen(profileId: profileId);
        },
      ),
    ],
  );
}

class _RouterRefreshNotifier extends ChangeNotifier {
  _RouterRefreshNotifier(WidgetRef ref) {
    _subs = [
      ref.listenManual(authStateProvider, (_, _) => notifyListeners()),
      ref.listenManual(adminSessionProvider, (_, _) => notifyListeners()),
      ref.listenManual(studentAuthProvider, (_, _) => notifyListeners()),
      ref.listenManual(studentSessionProvider, (_, _) => notifyListeners()),
      ref.listenManual(kioskModeProvider, (_, _) => notifyListeners()),
      ref.listenManual(appSetupStatusProvider, (_, _) => notifyListeners()),
    ];
  }

  late final List<ProviderSubscription<dynamic>> _subs;

  @override
  void dispose() {
    for (final sub in _subs) {
      sub.close();
    }
    super.dispose();
  }
}
