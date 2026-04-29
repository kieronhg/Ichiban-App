import 'package:equatable/equatable.dart';

class PricingChangeLog extends Equatable {
  final String id;
  final String planTypeKey;
  final double previousAmount;
  final double newAmount;
  final String changedByAdminId;
  final DateTime changedAt;

  const PricingChangeLog({
    required this.id,
    required this.planTypeKey,
    required this.previousAmount,
    required this.newAmount,
    required this.changedByAdminId,
    required this.changedAt,
  });

  @override
  List<Object?> get props => [
    id,
    planTypeKey,
    previousAmount,
    newAmount,
    changedByAdminId,
    changedAt,
  ];
}
