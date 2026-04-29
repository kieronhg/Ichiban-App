class RouteNames {
  RouteNames._();

  // Shared
  static const String entry = '/';

  // Admin
  static const String adminSetup = '/admin/setup';
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
  static const String adminGradingCreate = '/admin/grading/create';
  static const String adminGradingDetail = '/admin/grading/:eventId';
  static const String adminGradingNominate = '/admin/grading/:eventId/nominate';
  static const String adminGradingRecordResults =
      '/admin/grading/:eventId/record-results';
  static const String adminMemberships = '/admin/memberships';
  static const String adminMembershipsCreate = '/admin/memberships/create';
  static const String adminMembershipsDetail =
      '/admin/memberships/:membershipId';
  static const String adminMembershipsRenew =
      '/admin/memberships/:membershipId/renew';
  static const String adminMembershipsConvert =
      '/admin/memberships/:membershipId/convert';
  static const String adminPayments = '/admin/payments';
  static const String adminPaymentsDetail = '/admin/payments/:paymentId';
  static const String adminPaymentsRecord = '/admin/payments/record';
  static const String adminPaymentsReport = '/admin/payments/report';
  static const String adminPaymentsBulkResolve =
      '/admin/payments/bulk-resolve/:profileId';
  static const String adminTeam = '/admin/team';
  static const String adminTeamInvite = '/admin/team/invite';
  static const String adminTeamDetail = '/admin/team/:uid';
  static const String adminTeamEdit = '/admin/team/:uid/edit';
  static const String adminNotifications = '/admin/notifications';
  static const String adminNotificationDetail =
      '/admin/notifications/:notificationId';
  static const String adminSendAnnouncement = '/admin/notifications/announce';
  static const String adminEmailTemplates = '/admin/notifications/templates';
  static const String adminEmailTemplateEditor =
      '/admin/notifications/templates/:templateKey';
  static const String adminSettings = '/admin/settings';
  static const String adminSettingsGeneral = '/admin/settings/general';
  static const String adminSettingsPricing = '/admin/settings/pricing';
  static const String adminSettingsNotifications =
      '/admin/settings/notification-timings';
  static const String adminSettingsGdpr = '/admin/settings/gdpr';
  static const String adminSettingsEmailTemplates =
      '/admin/settings/email-templates';
  static const String adminSettingsDangerZone = '/admin/settings/danger-zone';
  static const String adminMyProfile = '/admin/my-profile';
  static const String adminMyProfileEdit = '/admin/my-profile/edit';
  static const String adminMyProfileDbs = '/admin/my-profile/dbs';
  static const String adminMyProfileFirstAid = '/admin/my-profile/firstaid';
  static const String adminTeamComplianceEdit =
      '/admin/team/:uid/compliance/edit';

  // Student
  static const String studentNotifications = '/student/notifications';
  static const String studentSelect = '/student/select';
  static const String studentPin = '/student/pin';
  static const String studentHome = '/student/home';
  static const String studentCheckin = '/student/checkin';
  static const String studentAttendance = '/student/attendance';
  static const String studentGrades = '/student/grades';
  static const String studentProfile = '/student/profile';
}
