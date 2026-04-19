import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/firebase_auth_repository.dart';
import '../../data/repositories/firestore_app_settings_repository.dart';
import '../../data/repositories/firestore_attendance_repository.dart';
import '../../data/repositories/firestore_cash_payment_repository.dart';
import '../../data/repositories/firestore_discipline_repository.dart';
import '../../data/repositories/firestore_email_template_repository.dart';
import '../../data/repositories/firestore_enrollment_repository.dart';
import '../../data/repositories/firestore_grading_repository.dart';
import '../../data/repositories/firestore_membership_pricing_repository.dart';
import '../../data/repositories/firestore_membership_repository.dart';
import '../../data/repositories/firestore_notification_repository.dart';
import '../../data/repositories/firestore_payt_session_repository.dart';
import '../../data/repositories/firestore_profile_repository.dart';
import '../../data/repositories/firestore_rank_repository.dart';

import '../../domain/repositories/app_settings_repository.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/repositories/attendance_repository.dart';
import '../../domain/repositories/cash_payment_repository.dart';
import '../../domain/repositories/discipline_repository.dart';
import '../../domain/repositories/email_template_repository.dart';
import '../../domain/repositories/enrollment_repository.dart';
import '../../domain/repositories/grading_repository.dart';
import '../../domain/repositories/membership_pricing_repository.dart';
import '../../domain/repositories/membership_repository.dart';
import '../../domain/repositories/notification_repository.dart';
import '../../domain/repositories/payt_session_repository.dart';
import '../../domain/repositories/profile_repository.dart';
import '../../domain/repositories/rank_repository.dart';

// ── Auth ───────────────────────────────────────────────────────────────────

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => FirebaseAuthRepository(),
);

// ── Profile ────────────────────────────────────────────────────────────────

final profileRepositoryProvider = Provider<ProfileRepository>(
  (ref) => FirestoreProfileRepository(),
);

// ── Membership ─────────────────────────────────────────────────────────────

final membershipRepositoryProvider = Provider<MembershipRepository>(
  (ref) => FirestoreMembershipRepository(),
);

final membershipPricingRepositoryProvider =
    Provider<MembershipPricingRepository>(
      (ref) => FirestoreMembershipPricingRepository(),
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

// ── Attendance ─────────────────────────────────────────────────────────────

final attendanceRepositoryProvider = Provider<AttendanceRepository>(
  (ref) => FirestoreAttendanceRepository(),
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
