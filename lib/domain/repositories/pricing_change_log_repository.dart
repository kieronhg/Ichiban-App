import '../entities/pricing_change_log.dart';

abstract class PricingChangeLogRepository {
  Future<void> create(PricingChangeLog log);
}
