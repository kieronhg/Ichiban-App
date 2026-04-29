import 'package:uuid/uuid.dart';
import '../../entities/pricing_change_log.dart';
import '../../repositories/membership_pricing_repository.dart';
import '../../repositories/pricing_change_log_repository.dart';

class SaveMembershipPricesUseCase {
  const SaveMembershipPricesUseCase(this._pricing, this._logs);

  final MembershipPricingRepository _pricing;
  final PricingChangeLogRepository _logs;

  /// [prices] is a map of planTypeKey → new amount.
  /// Only writes log records for prices that actually changed.
  Future<void> call({
    required Map<String, double> prices,
    required String changedByAdminId,
  }) async {
    final current = await _pricing.getAll();
    final currentMap = {for (final p in current) p.key: p.amount};

    for (final entry in prices.entries) {
      final previous = currentMap[entry.key];
      if (previous == null || previous == entry.value) continue;

      await _pricing.updatePrice(entry.key, entry.value);
      await _logs.create(
        PricingChangeLog(
          id: const Uuid().v4(),
          planTypeKey: entry.key,
          previousAmount: previous,
          newAmount: entry.value,
          changedByAdminId: changedByAdminId,
          changedAt: DateTime.now(),
        ),
      );
    }

    // Save prices that are new (not yet in Firestore) without logging
    for (final entry in prices.entries) {
      if (!currentMap.containsKey(entry.key)) {
        await _pricing.updatePrice(entry.key, entry.value);
      }
    }
  }
}
