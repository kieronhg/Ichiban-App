import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../domain/entities/app_setup.dart';

class AppSetupConverter {
  AppSetupConverter._();

  static AppSetup fromMap(Map<String, dynamic> map) {
    return AppSetup(
      setupComplete: map['setupComplete'] as bool? ?? false,
      setupCompletedAt: (map['setupCompletedAt'] as Timestamp?)?.toDate(),
      setupCompletedByAdminId: map['setupCompletedByAdminId'] as String?,
    );
  }

  static Map<String, dynamic> toMap(AppSetup appSetup) {
    return {
      'setupComplete': appSetup.setupComplete,
      'setupCompletedAt': appSetup.setupCompletedAt != null
          ? Timestamp.fromDate(appSetup.setupCompletedAt!)
          : null,
      'setupCompletedByAdminId': appSetup.setupCompletedByAdminId,
    };
  }
}
