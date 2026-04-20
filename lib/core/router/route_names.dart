class RouteNames {
  RouteNames._();

  // Shared
  static const String splash = '/';

  // Admin flavor
  static const String adminLogin = '/admin/login';
  static const String adminDashboard = '/admin/dashboard';
  static const String adminProfiles = '/admin/profiles';
  static const String adminProfileCreate = '/admin/profiles/create';
  static const String adminProfileDetail = '/admin/profiles/:id';
  static const String adminProfileEdit = '/admin/profiles/:id/edit';
  static const String adminDisciplines = '/admin/disciplines';
  static const String adminDisciplineCreate = '/admin/disciplines/create';
  static const String adminDisciplineDetail =
      '/admin/disciplines/:disciplineId';
  static const String adminDisciplineEdit =
      '/admin/disciplines/:disciplineId/edit';
  static const String adminRankCreate =
      '/admin/disciplines/:disciplineId/ranks/create';
  static const String adminRankEdit =
      '/admin/disciplines/:disciplineId/ranks/:rankId/edit';
  static const String adminProfileEnrol = '/admin/profiles/:id/enrol';
  static const String adminDisciplineBulkEnrol =
      '/admin/disciplines/:disciplineId/bulk-enrol';
  static const String adminBulkEnrolPreview = '/admin/bulk-enrol/preview';
  static const String adminEnrollment = '/admin/enrollment';
  static const String adminAttendance = '/admin/attendance';
  static const String adminAttendanceCreate = '/admin/attendance/create';
  static const String adminAttendanceDetail = '/admin/attendance/:sessionId';
  static const String adminAttendanceQueued = '/admin/attendance/queued';
  static const String adminGrading = '/admin/grading';
  static const String adminMemberships = '/admin/memberships';
  static const String adminPayments = '/admin/payments';
  static const String adminNotifications = '/admin/notifications';
  static const String adminSettings = '/admin/settings';

  // Student flavor
  static const String studentSelect = '/student/select';
  static const String studentPin = '/student/pin';
  static const String studentHome = '/student/home';
  static const String studentCheckin = '/student/checkin';
  static const String studentAttendance = '/student/attendance';
  static const String studentGrades = '/student/grades';
  static const String studentProfile = '/student/profile';
}
