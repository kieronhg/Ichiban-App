import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/firebase_auth_repository.dart';
import '../../data/repositories/firestore_admin_user_repository.dart';
import '../../data/repositories/firestore_app_setup_repository.dart';
import '../../data/repositories/firestore_app_settings_repository.dart';
import '../../data/repositories/firestore_attendance_repository.dart';
import '../../data/repositories/firestore_queued_check_in_repository.dart';
import '../../data/repositories/firestore_cash_payment_repository.dart';
import '../../data/repositories/firestore_discipline_repository.dart';
import '../../data/repositories/firestore_email_template_repository.dart';
import '../../data/repositories/firestore_enrollment_repository.dart';
import '../../data/repositories/firestore_grading_repository.dart';
import '../../data/repositories/firestore_profile_repository.dart';
import '../../data/repositories/firestore_grading_event_repository.dart';
import '../../data/repositories/firestore_grading_event_student_repository.dart';
import '../../data/repositories/firestore_membership_pricing_repository.dart';
import '../../data/repositories/firestore_pricing_change_log_repository.dart';
import '../../data/repositories/firestore_membership_repository.dart';
import '../../data/repositories/firestore_membership_history_repository.dart';
import '../../data/repositories/firestore_notification_repository.dart';
import '../../data/repositories/firestore_payt_session_repository.dart';
import '../../data/repositories/firestore_rank_repository.dart';

import '../../domain/repositories/admin_user_repository.dart';
import '../../domain/repositories/app_setup_repository.dart';
import '../../domain/repositories/app_settings_repository.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/repositories/attendance_repository.dart';
import '../../domain/repositories/queued_check_in_repository.dart';
import '../../domain/repositories/cash_payment_repository.dart';
import '../../domain/repositories/discipline_repository.dart';
import '../../domain/repositories/email_template_repository.dart';
import '../../domain/repositories/enrollment_repository.dart';
import '../../domain/repositories/grading_repository.dart';
import '../../domain/repositories/grading_event_repository.dart';
import '../../domain/repositories/grading_event_student_repository.dart';
import '../../domain/repositories/membership_pricing_repository.dart';
import '../../domain/repositories/pricing_change_log_repository.dart';
import '../../domain/repositories/membership_repository.dart';
import '../../domain/repositories/membership_history_repository.dart';
import '../../domain/repositories/notification_repository.dart';
import '../../domain/repositories/payt_session_repository.dart';
import '../../domain/repositories/profile_repository.dart';
import '../../domain/repositories/rank_repository.dart';

// ── Auth ───────────────────────────────────────────────────────────────────

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => FirebaseAuthRepository(),
);

// ── Admin Users ────────────────────────────────────────────────────────────

final adminUserRepositoryProvider = Provider<AdminUserRepository>(
  (ref) => FirestoreAdminUserRepository(),
);

// ── App Setup ──────────────────────────────────────────────────────────────

final appSetupRepositoryProvider = Provider<AppSetupRepository>(
  (ref) => FirestoreAppSetupRepository(),
);

// ── Profile ────────────────────────────────────────────────────────────────

final profileRepositoryProvider = Provider<ProfileRepository>(
  (ref) => FirestoreProfileRepository(),
);

// ── Membership ─────────────────────────────────────────────────────────────

final membershipRepositoryProvider = Provider<MembershipRepository>(
  (ref) => FirestoreMembershipRepository(),
);

final membershipHistoryRepositoryProvider =
    Provider<MembershipHistoryRepository>(
      (ref) => FirestoreMembershipHistoryRepository(),
    );

final membershipPricingRepositoryProvider =
    Provider<MembershipPricingRepository>(
      (ref) => FirestoreMembershipPricingRepository(),
    );

final pricingChangeLogRepositoryProvider = Provider<PricingChangeLogRepository>(
  (ref) => FirestorePricingChangeLogRepository(),
);

// ── Payments ───────────────────────────────────────────────────────────────

final paytSessionRepositoryProvider = Provider<PaytSessionRepository>(
  (ref) => FirestorePaytSessionRepository(),
);

final cashPaymentRepositoryProvider = Provider<CashPaymentRepository>(
  (ref) => FirestoreCashPaymentRepository(),
);

// ── Disciplines & Ranks ────────────────────────────────────────────────────

final disciplineRepositoryProvider = Provider<DisciplineRepository>(
  (ref) => FirestoreDisciplineRepository(),
);

final rankRepositoryProvider = Provider<RankRepository>(
  (ref) => FirestoreRankRepository(),
);

// ── Enrollment & Grading ───────────────────────────────────────────────────

final enrollmentRepositoryProvider = Provider<EnrollmentRepository>(
  (ref) => FirestoreEnrollmentRepository(),
);

final gradingRepositoryProvider = Provider<GradingRepository>(
  (ref) => FirestoreGradingRepository(),
);

final gradingEventRepositoryProvider = Provider<GradingEventRepository>(
  (ref) => FirestoreGradingEventRepository(),
);

final gradingEventStudentRepositoryProvider =
    Provider<GradingEventStudentRepository>(
      (ref) => FirestoreGradingEventStudentRepository(),
    );

// ── Attendance ─────────────────────────────────────────────────────────────

final attendanceRepositoryProvider = Provider<AttendanceRepository>(
  (ref) => FirestoreAttendanceRepository(),
);

final queuedCheckInRepositoryProvider = Provider<QueuedCheckInRepository>(
  (ref) => FirestoreQueuedCheckInRepository(),
);

// ── Notifications ──────────────────────────────────────────────────────────

final notificationRepositoryProvider = Provider<NotificationRepository>(
  (ref) => FirestoreNotificationRepository(),
);

// ── Settings & Templates ───────────────────────────────────────────────────

final appSettingsRepositoryProvider = Provider<AppSettingsRepository>(
  (ref) => FirestoreAppSettingsRepository(),
);

final emailTemplateRepositoryProvider = Provider<EmailTemplateRepository>(
  (ref) => FirestoreEmailTemplateRepository(),
);
