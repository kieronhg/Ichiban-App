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

enum MembershipStatus { trial, active, lapsed, cancelled, expired }

enum PaymentMethod { card, cash, none }

enum PaytPaymentStatus { pending, paid }

enum CheckInMethod { self, coach }

enum QueuedCheckInStatus { pending, resolved, discarded }

enum NotificationChannel { push, email }

enum NotificationType {
  renewalReminderPre,
  renewalReminderPost,
  trialExpiring,
  gradingEligibility,
  licenceReminder,
}

enum EmailDeliveryStatus { sent, failed }
