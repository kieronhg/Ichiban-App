import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants/app_constants.dart';
import '../../domain/entities/admin_user.dart';
import '../../domain/entities/app_setup.dart';
import '../../domain/entities/profile.dart';
import '../../domain/entities/membership.dart';
import '../../domain/entities/membership_history.dart';
import '../../domain/entities/membership_pricing.dart';
import '../../domain/entities/payt_session.dart';
import '../../domain/entities/cash_payment.dart';
import '../../domain/entities/discipline.dart';
import '../../domain/entities/rank.dart';
import '../../domain/entities/enrollment.dart';
import '../../domain/entities/grading_record.dart';
import '../../domain/entities/grading_event.dart';
import '../../domain/entities/grading_event_student.dart';
import '../../domain/entities/attendance_session.dart';
import '../../domain/entities/attendance_record.dart';
import '../../domain/entities/queued_check_in.dart';
import '../../domain/entities/notification_log.dart';
import '../../domain/entities/email_template.dart';
import '../../domain/entities/app_setting.dart';
import '../../domain/entities/pricing_change_log.dart';
import 'converters/profile_converter.dart';
import 'converters/membership_converter.dart';
import 'converters/membership_history_converter.dart';
import 'converters/membership_pricing_converter.dart';
import 'converters/payt_session_converter.dart';
import 'converters/cash_payment_converter.dart';
import 'converters/discipline_converter.dart';
import 'converters/rank_converter.dart';
import 'converters/enrollment_converter.dart';
import 'converters/grading_record_converter.dart';
import 'converters/grading_event_converter.dart';
import 'converters/grading_event_student_converter.dart';
import 'converters/attendance_session_converter.dart';
import 'converters/attendance_record_converter.dart';
import 'converters/queued_check_in_converter.dart';
import 'converters/notification_log_converter.dart';
import 'converters/email_template_converter.dart';
import 'converters/admin_user_converter.dart';
import 'converters/app_setting_converter.dart';
import 'converters/app_setup_converter.dart';
import 'converters/pricing_change_log_converter.dart';

/// Central access point for all typed Firestore collection references.
/// All collections use withConverter so snapshots are automatically
/// mapped to domain entities — no manual casting in repositories.
class FirestoreCollections {
  FirestoreCollections._();

  static FirebaseFirestore get _db => FirebaseFirestore.instance;

  // ── Profiles ────────────────────────────────────────────────────────────────

  static CollectionReference<Profile> profiles() => _db
      .collection(AppConstants.colProfiles)
      .withConverter<Profile>(
        fromFirestore: (snap, _) =>
            ProfileConverter.fromMap(snap.id, snap.data()!),
        toFirestore: (profile, _) => ProfileConverter.toMap(profile),
      );

  // ── Memberships ─────────────────────────────────────────────────────────────

  static CollectionReference<Membership> memberships() => _db
      .collection(AppConstants.colMemberships)
      .withConverter<Membership>(
        fromFirestore: (snap, _) =>
            MembershipConverter.fromMap(snap.id, snap.data()!),
        toFirestore: (membership, _) => MembershipConverter.toMap(membership),
      );

  // ── Membership History ──────────────────────────────────────────────────────

  static CollectionReference<MembershipHistory> membershipHistory() => _db
      .collection(AppConstants.colMembershipHistory)
      .withConverter<MembershipHistory>(
        fromFirestore: (snap, _) =>
            MembershipHistoryConverter.fromMap(snap.id, snap.data()!),
        toFirestore: (record, _) => MembershipHistoryConverter.toMap(record),
      );

  // ── Membership Pricing ──────────────────────────────────────────────────────

  static CollectionReference<MembershipPricing> membershipPricing() => _db
      .collection(AppConstants.colMembershipPricing)
      .withConverter<MembershipPricing>(
        fromFirestore: (snap, _) =>
            MembershipPricingConverter.fromMap(snap.id, snap.data()!),
        toFirestore: (pricing, _) => MembershipPricingConverter.toMap(pricing),
      );

  // ── PAYT Sessions ───────────────────────────────────────────────────────────

  static CollectionReference<PaytSession> paytSessions() => _db
      .collection(AppConstants.colPaytSessions)
      .withConverter<PaytSession>(
        fromFirestore: (snap, _) =>
            PaytSessionConverter.fromMap(snap.id, snap.data()!),
        toFirestore: (session, _) => PaytSessionConverter.toMap(session),
      );

  // ── Cash Payments ───────────────────────────────────────────────────────────

  static CollectionReference<CashPayment> cashPayments() => _db
      .collection(AppConstants.colCashPayments)
      .withConverter<CashPayment>(
        fromFirestore: (snap, _) =>
            CashPaymentConverter.fromMap(snap.id, snap.data()!),
        toFirestore: (payment, _) => CashPaymentConverter.toMap(payment),
      );

  // ── Disciplines ─────────────────────────────────────────────────────────────

  static CollectionReference<Discipline> disciplines() => _db
      .collection(AppConstants.colDisciplines)
      .withConverter<Discipline>(
        fromFirestore: (snap, _) =>
            DisciplineConverter.fromMap(snap.id, snap.data()!),
        toFirestore: (discipline, _) => DisciplineConverter.toMap(discipline),
      );

  // ── Ranks (subcollection of disciplines) ────────────────────────────────────

  static CollectionReference<Rank> ranks(String disciplineId) => _db
      .collection(AppConstants.colDisciplines)
      .doc(disciplineId)
      .collection(AppConstants.colRanks)
      .withConverter<Rank>(
        fromFirestore: (snap, _) =>
            RankConverter.fromMap(snap.id, disciplineId, snap.data()!),
        toFirestore: (rank, _) => RankConverter.toMap(rank),
      );

  // ── Enrollments ─────────────────────────────────────────────────────────────

  static CollectionReference<Enrollment> enrollments() => _db
      .collection(AppConstants.colEnrollments)
      .withConverter<Enrollment>(
        fromFirestore: (snap, _) =>
            EnrollmentConverter.fromMap(snap.id, snap.data()!),
        toFirestore: (enrollment, _) => EnrollmentConverter.toMap(enrollment),
      );

  // ── Grading Records ─────────────────────────────────────────────────────────

  static CollectionReference<GradingRecord> gradingRecords() => _db
      .collection(AppConstants.colGradingRecords)
      .withConverter<GradingRecord>(
        fromFirestore: (snap, _) =>
            GradingRecordConverter.fromMap(snap.id, snap.data()!),
        toFirestore: (record, _) => GradingRecordConverter.toMap(record),
      );

  // ── Grading Events ───────────────────────────────────────────────────────────

  static CollectionReference<GradingEvent> gradingEvents() => _db
      .collection(AppConstants.colGradingEvents)
      .withConverter<GradingEvent>(
        fromFirestore: (snap, _) =>
            GradingEventConverter.fromMap(snap.id, snap.data()!),
        toFirestore: (event, _) => GradingEventConverter.toMap(event),
      );

  // ── Grading Event Students ────────────────────────────────────────────────────

  static CollectionReference<GradingEventStudent> gradingEventStudents() => _db
      .collection(AppConstants.colGradingEventStudents)
      .withConverter<GradingEventStudent>(
        fromFirestore: (snap, _) =>
            GradingEventStudentConverter.fromMap(snap.id, snap.data()!),
        toFirestore: (student, _) =>
            GradingEventStudentConverter.toMap(student),
      );

  // ── Attendance Sessions ──────────────────────────────────────────────────────

  static CollectionReference<AttendanceSession> attendanceSessions() => _db
      .collection(AppConstants.colAttendanceSessions)
      .withConverter<AttendanceSession>(
        fromFirestore: (snap, _) =>
            AttendanceSessionConverter.fromMap(snap.id, snap.data()!),
        toFirestore: (session, _) => AttendanceSessionConverter.toMap(session),
      );

  // ── Attendance Records ───────────────────────────────────────────────────────

  static CollectionReference<AttendanceRecord> attendanceRecords() => _db
      .collection(AppConstants.colAttendanceRecords)
      .withConverter<AttendanceRecord>(
        fromFirestore: (snap, _) =>
            AttendanceRecordConverter.fromMap(snap.id, snap.data()!),
        toFirestore: (record, _) => AttendanceRecordConverter.toMap(record),
      );

  // ── Notification Logs ───────────────────────────────────────────────────────

  static CollectionReference<NotificationLog> notificationLogs() => _db
      .collection(AppConstants.colNotificationLogs)
      .withConverter<NotificationLog>(
        fromFirestore: (snap, _) =>
            NotificationLogConverter.fromMap(snap.id, snap.data()!),
        toFirestore: (log, _) => NotificationLogConverter.toMap(log),
      );

  // ── Email Templates ──────────────────────────────────────────────────────────

  static CollectionReference<EmailTemplate> emailTemplates() => _db
      .collection(AppConstants.colEmailTemplates)
      .withConverter<EmailTemplate>(
        fromFirestore: (snap, _) =>
            EmailTemplateConverter.fromMap(snap.id, snap.data()!),
        toFirestore: (template, _) => EmailTemplateConverter.toMap(template),
      );

  // ── Queued Check-Ins ─────────────────────────────────────────────────────────

  static CollectionReference<QueuedCheckIn> queuedCheckIns() => _db
      .collection(AppConstants.colQueuedCheckIns)
      .withConverter<QueuedCheckIn>(
        fromFirestore: (snap, _) =>
            QueuedCheckInConverter.fromMap(snap.id, snap.data()!),
        toFirestore: (q, _) => QueuedCheckInConverter.toMap(q),
      );

  // ── App Settings ─────────────────────────────────────────────────────────────

  static CollectionReference<AppSetting> appSettings() => _db
      .collection(AppConstants.colAppSettings)
      .withConverter<AppSetting>(
        fromFirestore: (snap, _) =>
            AppSettingConverter.fromMap(snap.id, snap.data()!),
        toFirestore: (setting, _) => AppSettingConverter.toMap(setting),
      );

  // ── Pricing Change Logs ──────────────────────────────────────────────────────

  static CollectionReference<PricingChangeLog> pricingChangeLogs() => _db
      .collection(AppConstants.colPricingChangeLogs)
      .withConverter<PricingChangeLog>(
        fromFirestore: (snap, _) =>
            PricingChangeLogConverter.fromMap(snap.id, snap.data()!),
        toFirestore: (log, _) => PricingChangeLogConverter.toMap(log),
      );

  // ── Admin Users ──────────────────────────────────────────────────────────────

  static CollectionReference<AdminUser> adminUsers() => _db
      .collection(AppConstants.colAdminUsers)
      .withConverter<AdminUser>(
        fromFirestore: (snap, _) =>
            AdminUserConverter.fromMap(snap.id, snap.data()!),
        toFirestore: (adminUser, _) => AdminUserConverter.toMap(adminUser),
      );

  // ── App Setup (single-document collection) ───────────────────────────────────

  static DocumentReference<AppSetup> appSetupDoc() => _db
      .collection(AppConstants.colAppSetup)
      .doc('status')
      .withConverter<AppSetup>(
        fromFirestore: (snap, _) =>
            AppSetupConverter.fromMap(snap.data() ?? {}),
        toFirestore: (setup, _) => AppSetupConverter.toMap(setup),
      );
}
