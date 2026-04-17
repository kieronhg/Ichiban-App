class AppConstants {
  AppConstants._();

  static const String appName = 'Ichiban';

  // Firestore collection names
  static const String colProfiles = 'profiles';
  static const String colProfileLinks = 'profileLinks';
  static const String colDisciplines = 'disciplines';
  static const String colRanks = 'ranks';
  static const String colMemberships = 'memberships';
  static const String colEnrollments = 'enrollments';
  static const String colGradingRecords = 'gradingRecords';
  static const String colAttendanceSessions = 'attendanceSessions';
  static const String colAttendanceRecords = 'attendanceRecords';
  static const String colNotificationLogs = 'notificationLogs';
  static const String colAppSettings = 'appSettings';

  // Shared preferences keys
  static const String prefActiveStudentId = 'active_student_id';
  static const String prefAdminUid = 'admin_uid';
  static const String prefAppFlavor = 'app_flavor';

  // Default notification lead times (days)
  static const int defaultRenewalReminderDays = 14;
  static const int defaultLicenceReminderDays = 30;

  // PIN length
  static const int pinLength = 4;
}
