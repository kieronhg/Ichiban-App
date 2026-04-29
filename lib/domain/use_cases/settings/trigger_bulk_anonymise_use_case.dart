import 'package:cloud_functions/cloud_functions.dart';

class TriggerBulkAnonymiseUseCase {
  const TriggerBulkAnonymiseUseCase();

  /// Calls the `bulkAnonymise` Cloud Function and returns the count of
  /// anonymised records. Throws [FirebaseFunctionsException] if the function
  /// is not yet deployed or fails.
  Future<int> call() async {
    final result = await FirebaseFunctions.instance
        .httpsCallable('bulkAnonymise')
        .call<Map<String, dynamic>>();
    return (result.data['count'] as num).toInt();
  }
}
