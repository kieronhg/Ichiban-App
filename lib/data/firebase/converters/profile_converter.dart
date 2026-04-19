import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../domain/entities/profile.dart';
import '../../../domain/entities/enums.dart';

class ProfileConverter {
  ProfileConverter._();

  static Profile fromMap(String id, Map<String, dynamic> map) {
    // profileTypes is stored as a List<String> in Firestore
    final rawTypes = (map['profileTypes'] as List<dynamic>?) ?? [];
    final profileTypes = rawTypes
        .map((t) => ProfileType.values.byName(t as String))
        .toList();

    // communicationPreferences is stored as a List<String> in Firestore
    final rawPrefs = (map['communicationPreferences'] as List<dynamic>?) ?? [];
    final communicationPreferences = rawPrefs
        .map((p) => NotificationChannel.values.byName(p as String))
        .toList();

    return Profile(
      id: id,
      firstName: map['firstName'] as String,
      lastName: map['lastName'] as String,
      dateOfBirth: (map['dateOfBirth'] as Timestamp).toDate(),
      profileTypes: profileTypes,
      gender: map['gender'] as String?,
      addressLine1: map['addressLine1'] as String,
      addressLine2: map['addressLine2'] as String?,
      city: map['city'] as String,
      county: map['county'] as String,
      postcode: map['postcode'] as String,
      country: map['country'] as String,
      phone: map['phone'] as String,
      email: map['email'] as String,
      emergencyContactName: map['emergencyContactName'] as String,
      emergencyContactRelationship:
          map['emergencyContactRelationship'] as String,
      emergencyContactPhone: map['emergencyContactPhone'] as String,
      allergiesOrMedicalNotes: map['allergiesOrMedicalNotes'] as String?,
      photoVideoConsent: map['photoVideoConsent'] as bool,
      notes: map['notes'] as String?,
      communicationPreferences: communicationPreferences,
      dataProcessingConsent: (map['dataProcessingConsent'] as bool?) ?? false,
      dataProcessingConsentDate:
          (map['dataProcessingConsentDate'] as Timestamp?)?.toDate(),
      dataProcessingConsentVersion:
          map['dataProcessingConsentVersion'] as String?,
      isAnonymised: (map['isAnonymised'] as bool?) ?? false,
      anonymisedAt: (map['anonymisedAt'] as Timestamp?)?.toDate(),
      registrationDate: (map['registrationDate'] as Timestamp).toDate(),
      isActive: map['isActive'] as bool,
      fcmToken: map['fcmToken'] as String?,
      pinHash: map['pinHash'] as String?,
      parentProfileId: map['parentProfileId'] as String?,
      secondParentProfileId: map['secondParentProfileId'] as String?,
      payingParentId: map['payingParentId'] as String?,
    );
  }

  static Map<String, dynamic> toMap(Profile profile) {
    return {
      'firstName': profile.firstName,
      'lastName': profile.lastName,
      'dateOfBirth': Timestamp.fromDate(profile.dateOfBirth),
      'profileTypes': profile.profileTypes.map((t) => t.name).toList(),
      'gender': profile.gender,
      'addressLine1': profile.addressLine1,
      'addressLine2': profile.addressLine2,
      'city': profile.city,
      'county': profile.county,
      'postcode': profile.postcode,
      'country': profile.country,
      'phone': profile.phone,
      'email': profile.email,
      'emergencyContactName': profile.emergencyContactName,
      'emergencyContactRelationship': profile.emergencyContactRelationship,
      'emergencyContactPhone': profile.emergencyContactPhone,
      'allergiesOrMedicalNotes': profile.allergiesOrMedicalNotes,
      'photoVideoConsent': profile.photoVideoConsent,
      'notes': profile.notes,
      'communicationPreferences': profile.communicationPreferences
          .map((p) => p.name)
          .toList(),
      'dataProcessingConsent': profile.dataProcessingConsent,
      'dataProcessingConsentDate': profile.dataProcessingConsentDate != null
          ? Timestamp.fromDate(profile.dataProcessingConsentDate!)
          : null,
      'dataProcessingConsentVersion': profile.dataProcessingConsentVersion,
      'isAnonymised': profile.isAnonymised,
      'anonymisedAt': profile.anonymisedAt != null
          ? Timestamp.fromDate(profile.anonymisedAt!)
          : null,
      'registrationDate': Timestamp.fromDate(profile.registrationDate),
      'isActive': profile.isActive,
      'fcmToken': profile.fcmToken,
      'pinHash': profile.pinHash,
      'parentProfileId': profile.parentProfileId,
      'secondParentProfileId': profile.secondParentProfileId,
      'payingParentId': profile.payingParentId,
    };
  }
}
