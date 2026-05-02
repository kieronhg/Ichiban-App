enum AdminRole { owner, coach }

enum RegistrationStatus { pendingVerification, trial, active, lapsed }

enum RankType { kyu, dan, mon, ungraded }

enum ProfileType { adultStudent, juniorStudent, coach, parentGuardian }

enum MembershipPlanType {
  monthlyAdult,
  monthlyJunior,
  annualAdult,
  annualJunior,
  familyMonthly,
  payAsYouTrainAdult,
  payAsYouTrainJunior,
  trial,
}

enum FamilyPricingTier { upToThree, fourOrMore }

enum MembershipStatus {
  trial,
  active,
  gracePeriod,
  lapsed,
  cancelled,
  expired,
  payt,
}

enum PaymentMethod { card, cash, bankTransfer, stripe, writtenOff, none }

enum PaymentType { membership, payt, other }

enum MembershipChangeType {
  created,
  renewed,
  lapsed,
  cancelled,
  reactivated,
  planChanged,
  statusOverride,
}

enum PaytPaymentStatus { pending, paid, writtenOff }

enum CheckInMethod { self, coach }

enum QueuedCheckInStatus { pending, resolved, discarded }

enum GradingOutcome { promoted, failed, absent }

enum GradingEventStatus { upcoming, completed, cancelled }

enum NotificationChannel { push, email }

enum NotificationType {
  lapseReminderPre,
  lapseReminderPost,
  trialExpiring,
  gradingEligibility,
  gradingPromotion,
  announcement,
  dbsExpiry,
  firstAidExpiry,
  complianceSubmitted,
  complianceVerified,
  coachComplianceExpiring,
  deliveryFailure,
  selfRegistration,
  paymentConfirmed,
  paymentFailed,
  gracePeriodStarted,
  membershipLapsed,
  inviteExpired,
  newSelfRegistration,
  downgradeRequested,
}

enum InviteStatus { notSent, pending, accepted, expired }

enum NotificationDeliveryStatus { sent, failed, suppressed }

enum RecipientType { member, admin }

enum AnnouncementAudience { all, discipline }

enum AnnouncementChannel { push, email, both }

enum DbsStatus { notSubmitted, pending, clear, expired }

enum CoachComplianceType { dbs, firstAid }
