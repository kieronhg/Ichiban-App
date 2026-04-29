class AppConstants {
  AppConstants._();

  static const String appName = 'Ichiban';

  // Firestore collection names
  static const String colProfiles = 'profiles';
  static const String colDisciplines = 'disciplines';
  static const String colRanks = 'ranks';
  static const String colMemberships = 'memberships';
  static const String colMembershipHistory = 'membershipHistory';
  static const String colMembershipPricing = 'membershipPricing';
  static const String colPaytSessions = 'paytSessions';
  static const String colCashPayments = 'cashPayments';
  static const String colEnrollments = 'enrollments';
  static const String colGradingRecords = 'gradingRecords';
  static const String colGradingEvents = 'gradingEvents';
  static const String colGradingEventStudents = 'gradingEventStudents';
  static const String colAttendanceSessions = 'attendanceSessions';
  static const String colAttendanceRecords = 'attendanceRecords';
  static const String colQueuedCheckIns = 'queuedCheckIns';
  static const String colNotificationLogs = 'notificationLogs';
  static const String colPricingChangeLogs = 'pricingChangeLogs';
  static const String colEmailTemplates = 'emailTemplates';
  static const String colAnnouncements = 'announcements';
  static const String colAppSettings = 'appSettings';
  static const String colAdminUsers = 'adminUsers';
  static const String colCoachProfiles = 'coachProfiles';
  static const String colAppSetup = 'appSetup';

  // Shared preferences keys
  static const String prefActiveStudentId = 'active_student_id';
  static const String prefAdminUid = 'admin_uid';
  static const String prefAppFlavor = 'app_flavor';

  // Default notification lead times (days)
  static const int defaultRenewalReminderDays = 14;
  static const int defaultLicenceReminderDays = 30;

  // PIN length
  static const int pinLength = 4;

  // Student PIN lockout
  /// Number of consecutive wrong PINs before the screen locks.
  static const int pinMaxAttempts = 5;

  /// How long (minutes) the PIN screen stays locked after max attempts.
  static const int pinLockoutMinutes = 5;

  /// Minutes of inactivity before the student session auto-signs-out.
  static const int studentSessionTimeoutMinutes = 5;
}
