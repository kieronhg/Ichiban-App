import 'package:equatable/equatable.dart';

class CommunicationPreferences extends Equatable {
  const CommunicationPreferences({
    this.billingAndPaymentReminders = false,
    this.gradingNotifications = false,
    this.trialExpiryReminders = false,
    this.generalDojoAnnouncements = false,
    this.membershipStatusChanges = true,
  });

  // Billing reminders are always sent regardless of this toggle — it exists
  // only so members can see the preference exists, not to suppress sends.
  final bool billingAndPaymentReminders;
  final bool gradingNotifications;
  final bool trialExpiryReminders;
  final bool generalDojoAnnouncements;
  final bool membershipStatusChanges;

  static const empty = CommunicationPreferences();

  CommunicationPreferences copyWith({
    bool? billingAndPaymentReminders,
    bool? gradingNotifications,
    bool? trialExpiryReminders,
    bool? generalDojoAnnouncements,
    bool? membershipStatusChanges,
  }) {
    return CommunicationPreferences(
      billingAndPaymentReminders:
          billingAndPaymentReminders ?? this.billingAndPaymentReminders,
      gradingNotifications: gradingNotifications ?? this.gradingNotifications,
      trialExpiryReminders: trialExpiryReminders ?? this.trialExpiryReminders,
      generalDojoAnnouncements:
          generalDojoAnnouncements ?? this.generalDojoAnnouncements,
      membershipStatusChanges:
          membershipStatusChanges ?? this.membershipStatusChanges,
    );
  }

  @override
  List<Object?> get props => [
    billingAndPaymentReminders,
    gradingNotifications,
    trialExpiryReminders,
    generalDojoAnnouncements,
    membershipStatusChanges,
  ];
}
