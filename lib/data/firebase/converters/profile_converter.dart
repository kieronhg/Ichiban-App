import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../domain/entities/profile.dart';
import '../../../domain/entities/enums.dart';

class ProfileConverter {
  ProfileConverter._();

  static Profile fromMap(String id, Map<String, dynamic> map) {
    return Profile(
      id: id,
      fullName: map['fullName'] as String,
      dateOfBirth: (map['dateOfBirth'] as Timestamp).toDate(),
      profileType: ProfileType.values.byName(map['profileType'] as String),
      addressLine1: map['addressLine1'] as String,
      addressLine2: map['addressLine2'] as String?,
      city: map['city'] as String,
      county: map['county'] as String,
      postcode: map['postcode'] as String,
      country: map['country'] as String,
      phone: map['phone'] as String,
      email: map['email'] as String,
      emergencyContactName: map['emergencyContactName'] as String,
      emergencyContactRelationship: map['emergencyContactRelationship'] as String,
      emergencyContactPhone: map['emergencyContactPhone'] as String,
      allergiesOrMedicalNotes: map['allergiesOrMedicalNotes'] as String?,
      photoVideoConsent: map['photoVideoConsent'] as bool,
      registrationDate: (map['registrationDate'] as Timestamp).toDate(),
      isActive: map['isActive'] as bool,
      fcmToken: map['fcmToken'] as String?,
      pinHash: map['pinHash'] as String?,
      parentProfileId: map['parentProfileId'] as String?,
    );
  }

  static Map<String, dynamic> toMap(Profile profile) {
    return {
      'fullName': profile.fullName,
      'dateOfBirth': Timestamp.fromDate(profile.dateOfBirth),
      'profileType': profile.profileType.name,
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
      'registrationDate': Timestamp.fromDate(profile.registrationDate),
      'isActive': profile.isActive,
      'fcmToken': profile.fcmToken,
      'pinHash': profile.pinHash,
      'parentProfileId': profile.parentProfileId,
    };
  }
}
