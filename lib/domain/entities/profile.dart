import 'package:equatable/equatable.dart';
import 'enums.dart';

class Profile extends Equatable {
  final String id;
  final String firstName;
  final String lastName;
  final DateTime dateOfBirth;

  /// A profile can hold more than one role — e.g. a person who is both an
  /// adult student and a coach.  At least one type is always present.
  final List<ProfileType> profileTypes;

  final String? gender;

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

  // Admin-only notes (not visible to the member)
  final String? notes;

  // Which notification channels the member has opted into
  final List<NotificationChannel> communicationPreferences;

  // System fields
  final DateTime registrationDate;
  final bool isActive;
  final String? fcmToken;
  final String? pinHash;

  // GDPR — data processing consent
  /// Must be true before a profile can be created.
  final bool dataProcessingConsent;

  /// Timestamp when consent was given.
  final DateTime? dataProcessingConsentDate;

  /// Version of the privacy policy agreed to (e.g. "1.0").
  final String? dataProcessingConsentVersion;

  // GDPR — anonymisation
  /// True once personal data has been wiped under Right to Erasure or
  /// the data retention policy.
  final bool isAnonymised;

  /// Timestamp when the profile was anonymised. Null if not yet anonymised.
  final DateTime? anonymisedAt;

  // Family links (juniors only)
  /// Primary parent/guardian profile ID.
  final String? parentProfileId;

  /// Optional second parent/guardian profile ID.
  final String? secondParentProfileId;

  /// Which parent profile is the paying member for this junior.
  final String? payingParentId;

  const Profile({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.dateOfBirth,
    required this.profileTypes,
    this.gender,
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
    this.notes,
    this.communicationPreferences = const [],
    this.dataProcessingConsent = false,
    this.dataProcessingConsentDate,
    this.dataProcessingConsentVersion,
    this.isAnonymised = false,
    this.anonymisedAt,
    required this.registrationDate,
    required this.isActive,
    this.fcmToken,
    this.pinHash,
    this.parentProfileId,
    this.secondParentProfileId,
    this.payingParentId,
  });

  // ── Computed ───────────────────────────────────────────────────────────────

  String get fullName => '$firstName $lastName';

  bool get isJunior => profileTypes.contains(ProfileType.juniorStudent);
  bool get isAdult => profileTypes.contains(ProfileType.adultStudent);
  bool get isCoach => profileTypes.contains(ProfileType.coach);
  bool get isParentGuardian =>
      profileTypes.contains(ProfileType.parentGuardian);

  // ── copyWith ───────────────────────────────────────────────────────────────

  Profile copyWith({
    String? id,
    String? firstName,
    String? lastName,
    DateTime? dateOfBirth,
    List<ProfileType>? profileTypes,
    String? gender,
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
    String? notes,
    List<NotificationChannel>? communicationPreferences,
    bool? dataProcessingConsent,
    DateTime? dataProcessingConsentDate,
    String? dataProcessingConsentVersion,
    bool? isAnonymised,
    DateTime? anonymisedAt,
    DateTime? registrationDate,
    bool? isActive,
    String? fcmToken,
    String? pinHash,

    /// Pass `true` to explicitly clear the PIN hash to null.
    /// Necessary because the standard [pinHash] parameter cannot distinguish
    /// "clear to null" from "leave unchanged" when using `??` semantics.
    bool clearPinHash = false,
    String? parentProfileId,
    String? secondParentProfileId,
    String? payingParentId,
  }) {
    return Profile(
      id: id ?? this.id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      profileTypes: profileTypes ?? this.profileTypes,
      gender: gender ?? this.gender,
      addressLine1: addressLine1 ?? this.addressLine1,
      addressLine2: addressLine2 ?? this.addressLine2,
      city: city ?? this.city,
      county: county ?? this.county,
      postcode: postcode ?? this.postcode,
      country: country ?? this.country,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      emergencyContactName: emergencyContactName ?? this.emergencyContactName,
      emergencyContactRelationship:
          emergencyContactRelationship ?? this.emergencyContactRelationship,
      emergencyContactPhone:
          emergencyContactPhone ?? this.emergencyContactPhone,
      allergiesOrMedicalNotes:
          allergiesOrMedicalNotes ?? this.allergiesOrMedicalNotes,
      photoVideoConsent: photoVideoConsent ?? this.photoVideoConsent,
      notes: notes ?? this.notes,
      communicationPreferences:
          communicationPreferences ?? this.communicationPreferences,
      dataProcessingConsent:
          dataProcessingConsent ?? this.dataProcessingConsent,
      dataProcessingConsentDate:
          dataProcessingConsentDate ?? this.dataProcessingConsentDate,
      dataProcessingConsentVersion:
          dataProcessingConsentVersion ?? this.dataProcessingConsentVersion,
      isAnonymised: isAnonymised ?? this.isAnonymised,
      anonymisedAt: anonymisedAt ?? this.anonymisedAt,
      registrationDate: registrationDate ?? this.registrationDate,
      isActive: isActive ?? this.isActive,
      fcmToken: fcmToken ?? this.fcmToken,
      pinHash: clearPinHash ? null : (pinHash ?? this.pinHash),
      parentProfileId: parentProfileId ?? this.parentProfileId,
      secondParentProfileId:
          secondParentProfileId ?? this.secondParentProfileId,
      payingParentId: payingParentId ?? this.payingParentId,
    );
  }

  // ── Equatable ──────────────────────────────────────────────────────────────

  @override
  List<Object?> get props => [
    id,
    firstName,
    lastName,
    dateOfBirth,
    profileTypes,
    gender,
    addressLine1,
    addressLine2,
    city,
    county,
    postcode,
    country,
    phone,
    email,
    emergencyContactName,
    emergencyContactRelationship,
    emergencyContactPhone,
    allergiesOrMedicalNotes,
    photoVideoConsent,
    notes,
    communicationPreferences,
    dataProcessingConsent,
    dataProcessingConsentDate,
    dataProcessingConsentVersion,
    isAnonymised,
    anonymisedAt,
    registrationDate,
    isActive,
    fcmToken,
    pinHash,
    parentProfileId,
    secondParentProfileId,
    payingParentId,
  ];
}
