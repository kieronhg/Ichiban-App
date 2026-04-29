import '../../domain/entities/pricing_change_log.dart';
import '../../domain/repositories/pricing_change_log_repository.dart';
import '../firebase/firestore_collections.dart';

class FirestorePricingChangeLogRepository
    implements PricingChangeLogRepository {
  @override
  Future<void> create(PricingChangeLog log) async {
    await FirestoreCollections.pricingChangeLogs().add(log);
  }
}
