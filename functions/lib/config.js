"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.FCM_STALE_DAYS = exports.ROLE_OWNER = exports.OUTCOME_PROMOTED = exports.CHANNEL_EMAIL = exports.CHANNEL_PUSH = exports.RECIPIENT_ADMIN = exports.RECIPIENT_MEMBER = exports.DELIVERY_SUPPRESSED = exports.DELIVERY_FAILED = exports.DELIVERY_SENT = exports.NOTIF_DELIVERY_FAILURE = exports.NOTIF_COMPLIANCE_VERIFIED = exports.NOTIF_COMPLIANCE_SUBMITTED = exports.NOTIF_FIRST_AID_EXPIRY = exports.NOTIF_DBS_EXPIRY = exports.NOTIF_ANNOUNCEMENT = exports.NOTIF_GRADING_PROMOTION = exports.NOTIF_GRADING_ELIGIBILITY = exports.NOTIF_TRIAL_EXPIRING = exports.NOTIF_LAPSE_REMINDER_POST = exports.NOTIF_LAPSE_REMINDER_PRE = exports.CHANGE_TYPE_CANCELLED = exports.CHANGE_TYPE_LAPSED = exports.STATUS_PAYT = exports.STATUS_CANCELLED = exports.STATUS_TRIAL = exports.STATUS_EXPIRED = exports.STATUS_LAPSED = exports.STATUS_ACTIVE = exports.COL_APP_SETTINGS = exports.COL_EMAIL_TEMPLATES = exports.COL_ANNOUNCEMENTS = exports.COL_NOTIFICATION_LOGS = exports.COL_GRADING_RECORDS = exports.COL_GRADING_EVENTS = exports.COL_GRADING_EVENT_STUDENTS = exports.COL_MEMBERSHIP_HISTORY = exports.COL_MEMBERSHIPS = exports.COL_ADMIN_USERS = exports.COL_PROFILES = void 0;
// Firestore collection names — mirror lib/core/constants/app_constants.dart
exports.COL_PROFILES = "profiles";
exports.COL_ADMIN_USERS = "adminUsers";
exports.COL_MEMBERSHIPS = "memberships";
exports.COL_MEMBERSHIP_HISTORY = "membershipHistory";
exports.COL_GRADING_EVENT_STUDENTS = "gradingEventStudents";
exports.COL_GRADING_EVENTS = "gradingEvents";
exports.COL_GRADING_RECORDS = "gradingRecords";
exports.COL_NOTIFICATION_LOGS = "notificationLogs";
exports.COL_ANNOUNCEMENTS = "announcements";
exports.COL_EMAIL_TEMPLATES = "emailTemplates";
exports.COL_APP_SETTINGS = "appSettings";
// Membership status values — mirror MembershipStatus enum
exports.STATUS_ACTIVE = "active";
exports.STATUS_LAPSED = "lapsed";
exports.STATUS_EXPIRED = "expired";
exports.STATUS_TRIAL = "trial";
exports.STATUS_CANCELLED = "cancelled";
exports.STATUS_PAYT = "payt";
// MembershipChangeType values
exports.CHANGE_TYPE_LAPSED = "lapsed";
exports.CHANGE_TYPE_CANCELLED = "cancelled";
// NotificationType values — mirror NotificationType enum
exports.NOTIF_LAPSE_REMINDER_PRE = "lapseReminderPre";
exports.NOTIF_LAPSE_REMINDER_POST = "lapseReminderPost";
exports.NOTIF_TRIAL_EXPIRING = "trialExpiring";
exports.NOTIF_GRADING_ELIGIBILITY = "gradingEligibility";
exports.NOTIF_GRADING_PROMOTION = "gradingPromotion";
exports.NOTIF_ANNOUNCEMENT = "announcement";
exports.NOTIF_DBS_EXPIRY = "dbsExpiry";
exports.NOTIF_FIRST_AID_EXPIRY = "firstAidExpiry";
exports.NOTIF_COMPLIANCE_SUBMITTED = "complianceSubmitted";
exports.NOTIF_COMPLIANCE_VERIFIED = "complianceVerified";
exports.NOTIF_DELIVERY_FAILURE = "deliveryFailure";
// NotificationDeliveryStatus values
exports.DELIVERY_SENT = "sent";
exports.DELIVERY_FAILED = "failed";
exports.DELIVERY_SUPPRESSED = "suppressed";
// RecipientType values
exports.RECIPIENT_MEMBER = "member";
exports.RECIPIENT_ADMIN = "admin";
// NotificationChannel values
exports.CHANNEL_PUSH = "push";
exports.CHANNEL_EMAIL = "email";
// GradingOutcome values
exports.OUTCOME_PROMOTED = "promoted";
// AdminRole values
exports.ROLE_OWNER = "owner";
// Stale FCM token threshold
exports.FCM_STALE_DAYS = 30;
//# sourceMappingURL=config.js.map