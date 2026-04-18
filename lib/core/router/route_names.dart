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
  static const String adminEnrollment = '/admin/enrollment';
  static const String adminAttendance = '/admin/attendance';
  static const String adminGrading = '/admin/grading';
  static const String adminMemberships = '/admin/memberships';
  static const String adminPayments = '/admin/payments';
  static const String adminNotifications = '/admin/notifications';
  static const String adminSettings = '/admin/settings';

  // Student flavor
  static const String studentSelect = '/student/select';
  static const String studentPin = '/student/pin';
  static const String studentHome = '/student/home';
  static const String studentAttendance = '/student/attendance';
  static const String studentGrades = '/student/grades';
  static const String studentProfile = '/student/profile';
}
