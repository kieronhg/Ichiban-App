// Firestore collection names — mirror lib/core/constants/app_constants.dart
export const COL_PROFILES = "profiles";
export const COL_ADMIN_USERS = "adminUsers";
export const COL_MEMBERSHIPS = "memberships";
export const COL_MEMBERSHIP_HISTORY = "membershipHistory";
export const COL_GRADING_EVENT_STUDENTS = "gradingEventStudents";
export const COL_GRADING_EVENTS = "gradingEvents";
export const COL_GRADING_RECORDS = "gradingRecords";
export const COL_NOTIFICATION_LOGS = "notificationLogs";
export const COL_ANNOUNCEMENTS = "announcements";
export const COL_EMAIL_TEMPLATES = "emailTemplates";
export const COL_APP_SETTINGS = "appSettings";
export const COL_COACH_PROFILES = "coachProfiles";

// Membership status values — mirror MembershipStatus enum
export const STATUS_ACTIVE = "active";
export const STATUS_LAPSED = "lapsed";
export const STATUS_EXPIRED = "expired";
export const STATUS_TRIAL = "trial";
export const STATUS_CANCELLED = "cancelled";
export const STATUS_PAYT = "payt";

// MembershipChangeType values
export const CHANGE_TYPE_LAPSED = "lapsed";
export const CHANGE_TYPE_CANCELLED = "cancelled";

// NotificationType values — mirror NotificationType enum
export const NOTIF_LAPSE_REMINDER_PRE = "lapseReminderPre";
export const NOTIF_LAPSE_REMINDER_POST = "lapseReminderPost";
export const NOTIF_TRIAL_EXPIRING = "trialExpiring";
export const NOTIF_GRADING_ELIGIBILITY = "gradingEligibility";
export const NOTIF_GRADING_PROMOTION = "gradingPromotion";
export const NOTIF_ANNOUNCEMENT = "announcement";
export const NOTIF_DBS_EXPIRY = "dbsExpiry";
export const NOTIF_FIRST_AID_EXPIRY = "firstAidExpiry";
export const NOTIF_COMPLIANCE_SUBMITTED = "complianceSubmitted";
export const NOTIF_COMPLIANCE_VERIFIED = "complianceVerified";
export const NOTIF_DELIVERY_FAILURE = "deliveryFailure";

// NotificationDeliveryStatus values
export const DELIVERY_SENT = "sent";
export const DELIVERY_FAILED = "failed";
export const DELIVERY_SUPPRESSED = "suppressed";

// RecipientType values
export const RECIPIENT_MEMBER = "member";
export const RECIPIENT_ADMIN = "admin";

// NotificationChannel values
export const CHANNEL_PUSH = "push";
export const CHANNEL_EMAIL = "email";

// GradingOutcome values
export const OUTCOME_PROMOTED = "promoted";

// AdminRole values
export const ROLE_OWNER = "owner";

// Stale FCM token threshold
export const FCM_STALE_DAYS = 30;
