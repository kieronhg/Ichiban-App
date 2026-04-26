import 'package:equatable/equatable.dart';
import 'enums.dart';

/// Immutable audit record for a single membership state change.
///
/// Written on every create, renewal, lapse, cancellation, plan conversion,
/// manual status override, and reactivation. Cloud Functions set
/// [triggeredByCloudFunction] = true and leave [changedByAdminId] null.
class MembershipHistory extends Equatable {
  final String id;

  /// The membership this record belongs to.
  final String membershipId;

  final MembershipChangeType changeType;

  final MembershipStatus? previousStatus;
  final MembershipStatus newStatus;

  /// Set on [MembershipChangeType.planChanged] only.
  final MembershipPlanType? previousPlanType;

  /// Set on [MembershipChangeType.planChanged] only.
  final MembershipPlanType? newPlanType;

  /// Set on [MembershipChangeType.renewed] or [MembershipChangeType.planChanged].
  final double? previousAmount;

  /// Set on [MembershipChangeType.renewed] or [MembershipChangeType.planChanged].
  final double? newAmount;

  /// Null when triggered by a Cloud Function.
  final String? changedByAdminId;

  final bool triggeredByCloudFunction;
  final DateTime changedAt;
  final String? notes;

  const MembershipHistory({
    required this.id,
    required this.membershipId,
    required this.changeType,
    this.previousStatus,
    required this.newStatus,
    this.previousPlanType,
    this.newPlanType,
    this.previousAmount,
    this.newAmount,
    this.changedByAdminId,
    required this.triggeredByCloudFunction,
    required this.changedAt,
    this.notes,
  });

  @override
  List<Object?> get props => [
    id,
    membershipId,
    changeType,
    previousStatus,
    newStatus,
    previousPlanType,
    newPlanType,
    previousAmount,
    newAmount,
    changedByAdminId,
    triggeredByCloudFunction,
    changedAt,
    notes,
  ];
}
