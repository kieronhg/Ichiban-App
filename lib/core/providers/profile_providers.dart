import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/enums.dart';
import '../../domain/entities/profile.dart';
import '../../domain/use_cases/profile/create_profile_use_case.dart';
import '../../domain/use_cases/profile/deactivate_profile_use_case.dart';
import '../../domain/use_cases/profile/get_profile_use_case.dart';
import '../../domain/use_cases/profile/get_profiles_use_case.dart';
import '../../domain/use_cases/profile/set_pin_use_case.dart';
import '../../domain/use_cases/profile/update_profile_use_case.dart';
import 'app_settings_providers.dart';
import 'repository_providers.dart';

// ── Use-case providers ─────────────────────────────────────────────────────

final getProfilesUseCaseProvider = Provider<GetProfilesUseCase>(
  (ref) => GetProfilesUseCase(ref.watch(profileRepositoryProvider)),
);

final getProfileUseCaseProvider = Provider<GetProfileUseCase>(
  (ref) => GetProfileUseCase(ref.watch(profileRepositoryProvider)),
);

final createProfileUseCaseProvider = Provider<CreateProfileUseCase>(
  (ref) => CreateProfileUseCase(ref.watch(profileRepositoryProvider)),
);

final updateProfileUseCaseProvider = Provider<UpdateProfileUseCase>(
  (ref) => UpdateProfileUseCase(ref.watch(profileRepositoryProvider)),
);

final deactivateProfileUseCaseProvider = Provider<DeactivateProfileUseCase>(
  (ref) => DeactivateProfileUseCase(ref.watch(profileRepositoryProvider)),
);

final setPinUseCaseProvider = Provider<SetPinUseCase>(
  (ref) => SetPinUseCase(ref.watch(profileRepositoryProvider)),
);

// ── Stream providers ───────────────────────────────────────────────────────

/// All profiles, live.
final profileListProvider = StreamProvider<List<Profile>>(
  (ref) => ref.watch(getProfilesUseCaseProvider).watchAll(),
);

/// Profiles filtered by [ProfileType], live.
final profilesByTypeProvider =
    StreamProvider.family<List<Profile>, ProfileType>(
  (ref, type) => ref.watch(getProfilesUseCaseProvider).watchByType(type),
);

/// Single profile by ID, live. Emits null if not found.
final profileProvider = StreamProvider.family<Profile?, String>(
  (ref, id) => ref.watch(getProfileUseCaseProvider).watchById(id),
);

// ── Form notifier ──────────────────────────────────────────────────────────

/// Holds the mutable state for the create/edit profile form.
///
/// Pass an existing [Profile] to [ProfileFormNotifier.load] when editing.
/// Call [ProfileFormNotifier.save] to create or update.
class ProfileFormNotifier extends Notifier<ProfileFormState> {
  @override
  ProfileFormState build() => ProfileFormState.empty();

  void load(Profile profile) => state = ProfileFormState.fromProfile(profile);

  void setFirstName(String v) => state = state.copyWith(firstName: v);
  void setLastName(String v) => state = state.copyWith(lastName: v);
  void setDateOfBirth(DateTime v) => state = state.copyWith(dateOfBirth: v);
  void setGender(String? v) => state = state.copyWith(gender: v);
  void setProfileTypes(List<ProfileType> v) =>
      state = state.copyWith(profileTypes: v);
  void setAddressLine1(String v) => state = state.copyWith(addressLine1: v);
  void setAddressLine2(String? v) => state = state.copyWith(addressLine2: v);
  void setCity(String v) => state = state.copyWith(city: v);
  void setCounty(String v) => state = state.copyWith(county: v);
  void setPostcode(String v) => state = state.copyWith(postcode: v);
  void setCountry(String v) => state = state.copyWith(country: v);
  void setPhone(String v) => state = state.copyWith(phone: v);
  void setEmail(String v) => state = state.copyWith(email: v);
  void setEmergencyContactName(String v) =>
      state = state.copyWith(emergencyContactName: v);
  void setEmergencyContactRelationship(String v) =>
      state = state.copyWith(emergencyContactRelationship: v);
  void setEmergencyContactPhone(String v) =>
      state = state.copyWith(emergencyContactPhone: v);
  void setAllergiesOrMedicalNotes(String? v) =>
      state = state.copyWith(allergiesOrMedicalNotes: v);
  void setPhotoVideoConsent(bool v) =>
      state = state.copyWith(photoVideoConsent: v);
  void setNotes(String? v) => state = state.copyWith(notes: v);
  void setCommunicationPreferences(List<NotificationChannel> v) =>
      state = state.copyWith(communicationPreferences: v);
  void setParentProfileId(String? v) =>
      state = state.copyWith(parentProfileId: v);
  void setSecondParentProfileId(String? v) =>
      state = state.copyWith(secondParentProfileId: v);
  void setPayingParentId(String? v) =>
      state = state.copyWith(payingParentId: v);
  void setDataProcessingConsent(bool v) =>
      state = state.copyWith(dataProcessingConsent: v);
  void setDataProcessingConsentVersion(String? v) =>
      state = state.copyWith(dataProcessingConsentVersion: v);

  /// Creates or updates the profile. Returns the profile ID.
  Future<String> save() async {
    state = state.copyWith(isSaving: true, errorMessage: null);
    try {
      final profile = state.toProfile();
      final String id;
      if (profile.id.isEmpty) {
        id = await ref.read(createProfileUseCaseProvider)(profile);
      } else {
        await ref.read(updateProfileUseCaseProvider)(profile);
        id = profile.id;
      }
      state = state.copyWith(isSaving: false);
      return id;
    } catch (e) {
      state = state.copyWith(isSaving: false, errorMessage: e.toString());
      rethrow;
    }
  }
}

final profileFormNotifierProvider =
    NotifierProvider.autoDispose<ProfileFormNotifier, ProfileFormState>(
  ProfileFormNotifier.new,
);

// ── Form state ─────────────────────────────────────────────────────────────

class ProfileFormState {
  const ProfileFormState({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.dateOfBirth,
    required this.profileTypes,
    required this.gender,
    required this.addressLine1,
    required this.addressLine2,
    required this.city,
    required this.county,
    required this.postcode,
    required this.country,
    required this.phone,
    required this.email,
    required this.emergencyContactName,
    required this.emergencyContactRelationship,
    required this.emergencyContactPhone,
    required this.allergiesOrMedicalNotes,
    required this.photoVideoConsent,
    required this.notes,
    required this.communicationPreferences,
    required this.parentProfileId,
    required this.secondParentProfileId,
    required this.payingParentId,
    required this.dataProcessingConsent,
    required this.dataProcessingConsentVersion,
    required this.registrationDate,
    required this.isActive,
    required this.isSaving,
    required this.errorMessage,
  });

  final String id;
  final String firstName;
  final String lastName;
  final DateTime? dateOfBirth;
  final List<ProfileType> profileTypes;
  final String? gender;
  final String addressLine1;
  final String? addressLine2;
  final String city;
  final String county;
  final String postcode;
  final String country;
  final String phone;
  final String email;
  final String emergencyContactName;
  final String emergencyContactRelationship;
  final String emergencyContactPhone;
  final String? allergiesOrMedicalNotes;
  final bool photoVideoConsent;
  final String? notes;
  final List<NotificationChannel> communicationPreferences;
  final String? parentProfileId;
  final String? secondParentProfileId;
  final String? payingParentId;

  // GDPR consent
  final bool dataProcessingConsent;
  final String? dataProcessingConsentVersion;

  // Preserved system fields (edit mode)
  final DateTime? registrationDate;
  final bool isActive;

  final bool isSaving;
  final String? errorMessage;

  bool get isEditing => id.isNotEmpty;

  factory ProfileFormState.empty() => const ProfileFormState(
        id: '',
        firstName: '',
        lastName: '',
        dateOfBirth: null,
        profileTypes: [],
        gender: null,
        addressLine1: '',
        addressLine2: null,
        city: '',
        county: '',
        postcode: '',
        country: 'United Kingdom',
        phone: '',
        email: '',
        emergencyContactName: '',
        emergencyContactRelationship: '',
        emergencyContactPhone: '',
        allergiesOrMedicalNotes: null,
        photoVideoConsent: false,
        notes: null,
        communicationPreferences: [],
        parentProfileId: null,
        secondParentProfileId: null,
        payingParentId: null,
        dataProcessingConsent: false,
        dataProcessingConsentVersion: null,
        registrationDate: null,
        isActive: true,
        isSaving: false,
        errorMessage: null,
      );

  factory ProfileFormState.fromProfile(Profile p) => ProfileFormState(
        id: p.id,
        firstName: p.firstName,
        lastName: p.lastName,
        dateOfBirth: p.dateOfBirth,
        profileTypes: List.of(p.profileTypes),
        gender: p.gender,
        addressLine1: p.addressLine1,
        addressLine2: p.addressLine2,
        city: p.city,
        county: p.county,
        postcode: p.postcode,
        country: p.country,
        phone: p.phone,
        email: p.email,
        emergencyContactName: p.emergencyContactName,
        emergencyContactRelationship: p.emergencyContactRelationship,
        emergencyContactPhone: p.emergencyContactPhone,
        allergiesOrMedicalNotes: p.allergiesOrMedicalNotes,
        photoVideoConsent: p.photoVideoConsent,
        notes: p.notes,
        communicationPreferences: List.of(p.communicationPreferences),
        parentProfileId: p.parentProfileId,
        secondParentProfileId: p.secondParentProfileId,
        payingParentId: p.payingParentId,
        dataProcessingConsent: p.dataProcessingConsent,
        dataProcessingConsentVersion: p.dataProcessingConsentVersion,
        registrationDate: p.registrationDate,
        isActive: p.isActive,
        isSaving: false,
        errorMessage: null,
      );

  /// Converts form state back to a [Profile] for persistence.
  /// An empty string ID signals a new profile — Firestore will generate one.
  /// [registrationDate] is preserved from the loaded profile in edit mode;
  /// it defaults to now for new profiles and is overwritten by
  /// [CreateProfileUseCase] anyway.
  Profile toProfile() => Profile(
        id: id,
        firstName: firstName.trim(),
        lastName: lastName.trim(),
        dateOfBirth: dateOfBirth!,
        profileTypes: profileTypes,
        gender: gender,
        addressLine1: addressLine1.trim(),
        addressLine2: addressLine2?.trim(),
        city: city.trim(),
        county: county.trim(),
        postcode: postcode.trim(),
        country: country,
        phone: phone.trim(),
        email: email.trim(),
        emergencyContactName: emergencyContactName.trim(),
        emergencyContactRelationship: emergencyContactRelationship.trim(),
        emergencyContactPhone: emergencyContactPhone.trim(),
        allergiesOrMedicalNotes: allergiesOrMedicalNotes?.trim(),
        photoVideoConsent: photoVideoConsent,
        notes: notes?.trim(),
        communicationPreferences: communicationPreferences,
        dataProcessingConsent: dataProcessingConsent,
        dataProcessingConsentVersion: dataProcessingConsentVersion,
        registrationDate: registrationDate ?? DateTime.now(),
        isActive: isActive,
        parentProfileId: parentProfileId,
        secondParentProfileId: secondParentProfileId,
        payingParentId: payingParentId,
      );

  ProfileFormState copyWith({
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
    String? parentProfileId,
    String? secondParentProfileId,
    String? payingParentId,
    bool? dataProcessingConsent,
    String? dataProcessingConsentVersion,
    DateTime? registrationDate,
    bool? isActive,
    bool? isSaving,
    String? errorMessage,
  }) {
    return ProfileFormState(
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
      parentProfileId: parentProfileId ?? this.parentProfileId,
      secondParentProfileId:
          secondParentProfileId ?? this.secondParentProfileId,
      payingParentId: payingParentId ?? this.payingParentId,
      dataProcessingConsent:
          dataProcessingConsent ?? this.dataProcessingConsent,
      dataProcessingConsentVersion:
          dataProcessingConsentVersion ?? this.dataProcessingConsentVersion,
      registrationDate: registrationDate ?? this.registrationDate,
      isActive: isActive ?? this.isActive,
      isSaving: isSaving ?? this.isSaving,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}
