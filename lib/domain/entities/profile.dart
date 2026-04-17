import 'package:equatable/equatable.dart';
import 'enums.dart';

class Profile extends Equatable {
  final String id;
  final String fullName;
  final DateTime dateOfBirth;
  final ProfileType profileType;

  // Address
  final String addressLine1;
  final String? addressLine2;
  final String city;
  final String county;
  final String postcode;
  final String country;

  // Contact
  final String phone;
  final String email;

  // Emergency contact
  final String emergencyContactName;
  final String emergencyContactRelationship;
  final String emergencyContactPhone;

  // Medical & consent
  final String? allergiesOrMedicalNotes;
  final bool photoVideoConsent;

  // System fields
  final DateTime registrationDate;
  final bool isActive;
  final String? fcmToken;
  final String? pinHash;

  // Junior only — ref to parent/guardian profileId
  final String? parentProfileId;

  const Profile({
    required this.id,
    required this.fullName,
    required this.dateOfBirth,
    required this.profileType,
    required this.addressLine1,
    this.addressLine2,
    required this.city,
    required this.county,
    required this.postcode,
    required this.country,
    required this.phone,
    required this.email,
    required this.emergencyContactName,
    required this.emergencyContactRelationship,
    required this.emergencyContactPhone,
    this.allergiesOrMedicalNotes,
    required this.photoVideoConsent,
    required this.registrationDate,
    required this.isActive,
    this.fcmToken,
    this.pinHash,
    this.parentProfileId,
  });

  bool get isJunior => profileType == ProfileType.juniorStudent;
  bool get isAdult => profileType == ProfileType.adultStudent;
  bool get isCoach => profileType == ProfileType.coach;
  bool get isParentGuardian => profileType == ProfileType.parentGuardian;

  Profile copyWith({
    String? id,
    String? fullName,
    DateTime? dateOfBirth,
    ProfileType? profileType,
    String? addressLine1,
    String? addressLine2,
    String? city,
    String? county,
    String? postcode,
    String? country,
    String? phone,
    String? email,
    String? emergencyContactName,
    String? emergencyContactRelationship,
    String? emergencyContactPhone,
    String? allergiesOrMedicalNotes,
    bool? photoVideoConsent,
    DateTime? registrationDate,
    bool? isActive,
    String? fcmToken,
    String? pinHash,
    String? parentProfileId,
  }) {
    return Profile(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      profileType: profileType ?? this.profileType,
      addressLine1: addressLine1 ?? this.addressLine1,
      addressLine2: addressLine2 ?? this.addressLine2,
      city: city ?? this.city,
      county: county ?? this.county,
      postcode: postcode ?? this.postcode,
      country: country ?? this.country,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      emergencyContactName: emergencyContactName ?? this.emergencyContactName,
      emergencyContactRelationship: emergencyContactRelationship ?? this.emergencyContactRelationship,
      emergencyContactPhone: emergencyContactPhone ?? this.emergencyContactPhone,
      allergiesOrMedicalNotes: allergiesOrMedicalNotes ?? this.allergiesOrMedicalNotes,
      photoVideoConsent: photoVideoConsent ?? this.photoVideoConsent,
      registrationDate: registrationDate ?? this.registrationDate,
      isActive: isActive ?? this.isActive,
      fcmToken: fcmToken ?? this.fcmToken,
      pinHash: pinHash ?? this.pinHash,
      parentProfileId: parentProfileId ?? this.parentProfileId,
    );
  }

  @override
  List<Object?> get props => [
        id, fullName, dateOfBirth, profileType,
        addressLine1, addressLine2, city, county, postcode, country,
        phone, email,
        emergencyContactName, emergencyContactRelationship, emergencyContactPhone,
        allergiesOrMedicalNotes, photoVideoConsent,
        registrationDate, isActive, fcmToken, pinHash, parentProfileId,
      ];
}
