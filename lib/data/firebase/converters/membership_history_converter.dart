import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../domain/entities/membership_history.dart';
import '../../../domain/entities/enums.dart';

class MembershipHistoryConverter {
  MembershipHistoryConverter._();

  static MembershipHistory fromMap(String id, Map<String, dynamic> map) {
    return MembershipHistory(
      id: id,
      membershipId: map['membershipId'] as String,
      changeType: MembershipChangeType.values.byName(
        map['changeType'] as String,
      ),
      previousStatus: map['previousStatus'] != null
          ? MembershipStatus.values.byName(map['previousStatus'] as String)
          : null,
      newStatus: MembershipStatus.values.byName(map['newStatus'] as String),
      previousPlanType: map['previousPlanType'] != null
          ? MembershipPlanType.values.byName(map['previousPlanType'] as String)
          : null,
      newPlanType: map['newPlanType'] != null
          ? MembershipPlanType.values.byName(map['newPlanType'] as String)
          : null,
      previousAmount: (map['previousAmount'] as num?)?.toDouble(),
      newAmount: (map['newAmount'] as num?)?.toDouble(),
      changedByAdminId: map['changedByAdminId'] as String?,
      triggeredByCloudFunction:
          map['triggeredByCloudFunction'] as bool? ?? false,
      changedAt: (map['changedAt'] as Timestamp).toDate(),
      notes: map['notes'] as String?,
    );
  }

  static Map<String, dynamic> toMap(MembershipHistory record) {
    return {
      'membershipId': record.membershipId,
      'changeType': record.changeType.name,
      'previousStatus': record.previousStatus?.name,
      'newStatus': record.newStatus.name,
      'previousPlanType': record.previousPlanType?.name,
      'newPlanType': record.newPlanType?.name,
      'previousAmount': record.previousAmount,
      'newAmount': record.newAmount,
      'changedByAdminId': record.changedByAdminId,
      'triggeredByCloudFunction': record.triggeredByCloudFunction,
      'changedAt': Timestamp.fromDate(record.changedAt),
      'notes': record.notes,
    };
  }
}
