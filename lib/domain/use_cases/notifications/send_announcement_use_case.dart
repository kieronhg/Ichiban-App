import 'package:cloud_functions/cloud_functions.dart';

import '../../entities/enums.dart';

class SendAnnouncementUseCase {
  const SendAnnouncementUseCase();

  /// Calls the [sendAnnouncement] Firebase HTTP callable function.
  ///
  /// Returns a map containing deliveredCount, failedCount, recipientCount,
  /// and announcementId from the Cloud Function response.
  Future<Map<String, dynamic>> call({
    required String title,
    required String body,
    required AnnouncementChannel channel,
    required AnnouncementAudience audience,
    String? disciplineId,
  }) async {
    final callable = FirebaseFunctions.instance.httpsCallable(
      'sendAnnouncement',
    );
    final result = await callable.call({
      'title': title,
      'body': body,
      'channel': channel.name,
      'audience': audience.name,
      // ignore: use_null_aware_elements
      if (disciplineId != null) 'disciplineId': disciplineId,
    });
    return Map<String, dynamic>.from(result.data as Map);
  }
}
