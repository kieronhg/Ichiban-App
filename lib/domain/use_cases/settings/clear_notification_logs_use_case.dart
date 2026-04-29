import 'package:cloud_functions/cloud_functions.dart';

class ClearNotificationLogsUseCase {
  const ClearNotificationLogsUseCase();

  /// Calls the `clearNotificationLogs` Cloud Function and returns the count of
  /// deleted records. Throws [FirebaseFunctionsException] if the function is
  /// not yet deployed or fails.
  Future<int> call({required int olderThanDays}) async {
    if (olderThanDays < 1) {
      throw ArgumentError('olderThanDays must be at least 1');
    }
    final result = await FirebaseFunctions.instance
        .httpsCallable('clearNotificationLogs')
        .call<Map<String, dynamic>>({'olderThanDays': olderThanDays});
    return (result.data['count'] as num).toInt();
  }
}
