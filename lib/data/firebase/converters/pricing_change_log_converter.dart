import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../domain/entities/pricing_change_log.dart';

class PricingChangeLogConverter {
  PricingChangeLogConverter._();

  static PricingChangeLog fromMap(String id, Map<String, dynamic> map) {
    return PricingChangeLog(
      id: id,
      planTypeKey: map['planTypeKey'] as String,
      previousAmount: (map['previousAmount'] as num).toDouble(),
      newAmount: (map['newAmount'] as num).toDouble(),
      changedByAdminId: map['changedByAdminId'] as String,
      changedAt: (map['changedAt'] as Timestamp).toDate(),
    );
  }

  static Map<String, dynamic> toMap(PricingChangeLog log) {
    return {
      'planTypeKey': log.planTypeKey,
      'previousAmount': log.previousAmount,
      'newAmount': log.newAmount,
      'changedByAdminId': log.changedByAdminId,
      'changedAt': Timestamp.fromDate(log.changedAt),
    };
  }
}
