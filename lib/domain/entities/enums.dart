enum AdminRole { owner, coach }

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

enum MembershipStatus { trial, active, lapsed, cancelled, expired, payt }

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
  renewalReminderPre,
  renewalReminderPost,
  trialExpiring,
  gradingEligibility,
  gradingPromotion,
  licenceReminder,
}

enum EmailDeliveryStatus { sent, failed }
