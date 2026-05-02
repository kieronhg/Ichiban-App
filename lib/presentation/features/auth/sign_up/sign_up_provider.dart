import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/repository_providers.dart';
import '../../../../domain/entities/enums.dart';
import '../../../../domain/entities/notification_log.dart';
import '../../../../domain/entities/profile.dart';
import '../../../../domain/repositories/auth_repository.dart';

class ChildData {
  const ChildData({
    this.firstName = '',
    this.lastName = '',
    this.dateOfBirth,
    this.gender,
  });

  final String firstName;
  final String lastName;
  final DateTime? dateOfBirth;
  final String? gender;

  ChildData copyWith({
    String? firstName,
    String? lastName,
    DateTime? dateOfBirth,
    String? gender,
    bool clearDateOfBirth = false,
    bool clearGender = false,
  }) {
    return ChildData(
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      dateOfBirth: clearDateOfBirth ? null : (dateOfBirth ?? this.dateOfBirth),
      gender: clearGender ? null : (gender ?? this.gender),
    );
  }
}

class SignUpState {
  const SignUpState({
    this.email = '',
    this.password = '',
    this.confirmPassword = '',
    this.firstName = '',
    this.lastName = '',
    this.dateOfBirth,
    this.gender,
    this.addressLine1 = '',
    this.addressLine2,
    this.city = '',
    this.county = '',
    this.postcode = '',
    this.country = 'United Kingdom',
    this.phone = '',
    this.hasJuniors = false,
    this.children = const [],
    this.emergencyContactName = '',
    this.emergencyContactRelationship = '',
    this.emergencyContactPhone = '',
    this.allergiesOrMedicalNotes,
    this.selectedDisciplineIds = const [],
    this.dataProcessingConsent = false,
    this.photoVideoConsent = false,
    this.pin = '',
    this.confirmPin = '',
    this.currentStep = 1,
    this.isSubmitting = false,
    this.errorMessage,
    this.isComplete = false,
  });

  final String email;
  final String password;
  final String confirmPassword;

  final String firstName;
  final String lastName;
  final DateTime? dateOfBirth;
  final String? gender;
  final String addressLine1;
  final String? addressLine2;
  final String city;
  final String county;
  final String postcode;
  final String country;
  final String phone;
  final bool hasJuniors;
  final List<ChildData> children;

  final String emergencyContactName;
  final String emergencyContactRelationship;
  final String emergencyContactPhone;

  final String? allergiesOrMedicalNotes;

  final List<String> selectedDisciplineIds;

  final bool dataProcessingConsent;
  final bool photoVideoConsent;

  final String pin;
  final String confirmPin;

  final int currentStep;
  final bool isSubmitting;
  final String? errorMessage;
  final bool isComplete;

  static const int totalSteps = 10;

  SignUpState copyWith({
    String? email,
    String? password,
    String? confirmPassword,
    String? firstName,
    String? lastName,
    DateTime? dateOfBirth,
    String? gender,
    String? addressLine1,
    String? addressLine2,
    String? city,
    String? county,
    String? postcode,
    String? country,
    String? phone,
    bool? hasJuniors,
    List<ChildData>? children,
    String? emergencyContactName,
    String? emergencyContactRelationship,
    String? emergencyContactPhone,
    String? allergiesOrMedicalNotes,
    List<String>? selectedDisciplineIds,
    bool? dataProcessingConsent,
    bool? photoVideoConsent,
    String? pin,
    String? confirmPin,
    int? currentStep,
    bool? isSubmitting,
    String? errorMessage,
    bool clearErrorMessage = false,
    bool? isComplete,
    bool clearAllergies = false,
    bool clearDateOfBirth = false,
    bool clearAddressLine2 = false,
    bool clearGender = false,
  }) {
    return SignUpState(
      email: email ?? this.email,
      password: password ?? this.password,
      confirmPassword: confirmPassword ?? this.confirmPassword,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      dateOfBirth: clearDateOfBirth ? null : (dateOfBirth ?? this.dateOfBirth),
      gender: clearGender ? null : (gender ?? this.gender),
      addressLine1: addressLine1 ?? this.addressLine1,
      addressLine2: clearAddressLine2
          ? null
          : (addressLine2 ?? this.addressLine2),
      city: city ?? this.city,
      county: county ?? this.county,
      postcode: postcode ?? this.postcode,
      country: country ?? this.country,
      phone: phone ?? this.phone,
      hasJuniors: hasJuniors ?? this.hasJuniors,
      children: children ?? this.children,
      emergencyContactName: emergencyContactName ?? this.emergencyContactName,
      emergencyContactRelationship:
          emergencyContactRelationship ?? this.emergencyContactRelationship,
      emergencyContactPhone:
          emergencyContactPhone ?? this.emergencyContactPhone,
      allergiesOrMedicalNotes: clearAllergies
          ? null
          : (allergiesOrMedicalNotes ?? this.allergiesOrMedicalNotes),
      selectedDisciplineIds:
          selectedDisciplineIds ?? this.selectedDisciplineIds,
      dataProcessingConsent:
          dataProcessingConsent ?? this.dataProcessingConsent,
      photoVideoConsent: photoVideoConsent ?? this.photoVideoConsent,
      pin: pin ?? this.pin,
      confirmPin: confirmPin ?? this.confirmPin,
      currentStep: currentStep ?? this.currentStep,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: clearErrorMessage
          ? null
          : (errorMessage ?? this.errorMessage),
      isComplete: isComplete ?? this.isComplete,
    );
  }
}

class SignUpNotifier extends Notifier<SignUpState> {
  @override
  SignUpState build() => const SignUpState();

  void setEmail(String v) => state = state.copyWith(email: v);
  void setPassword(String v) => state = state.copyWith(password: v);
  void setConfirmPassword(String v) =>
      state = state.copyWith(confirmPassword: v);

  void setFirstName(String v) => state = state.copyWith(firstName: v);
  void setLastName(String v) => state = state.copyWith(lastName: v);
  void setDateOfBirth(DateTime? v) => v != null
      ? (state = state.copyWith(dateOfBirth: v))
      : (state = state.copyWith(clearDateOfBirth: true));
  void setGender(String? v) => v != null
      ? (state = state.copyWith(gender: v))
      : (state = state.copyWith(clearGender: true));
  void setAddressLine1(String v) => state = state.copyWith(addressLine1: v);
  void setAddressLine2(String? v) => (v == null || v.trim().isEmpty)
      ? (state = state.copyWith(clearAddressLine2: true))
      : (state = state.copyWith(addressLine2: v));
  void setCity(String v) => state = state.copyWith(city: v);
  void setCounty(String v) => state = state.copyWith(county: v);
  void setPostcode(String v) => state = state.copyWith(postcode: v);
  void setCountry(String v) => state = state.copyWith(country: v);
  void setPhone(String v) => state = state.copyWith(phone: v);

  void setHasJuniors(bool v) {
    if (v && state.children.isEmpty) {
      state = state.copyWith(hasJuniors: true, children: [const ChildData()]);
    } else if (!v) {
      state = state.copyWith(hasJuniors: false, children: []);
    } else {
      state = state.copyWith(hasJuniors: v);
    }
  }

  void addChild() {
    state = state.copyWith(children: [...state.children, const ChildData()]);
  }

  void removeChild(int index) {
    final updated = [...state.children]..removeAt(index);
    state = state.copyWith(children: updated, hasJuniors: updated.isNotEmpty);
  }

  void updateChild(int index, ChildData child) {
    final updated = [...state.children];
    if (index < updated.length) updated[index] = child;
    state = state.copyWith(children: updated);
  }

  void setEmergencyContactName(String v) =>
      state = state.copyWith(emergencyContactName: v);
  void setEmergencyContactRelationship(String v) =>
      state = state.copyWith(emergencyContactRelationship: v);
  void setEmergencyContactPhone(String v) =>
      state = state.copyWith(emergencyContactPhone: v);

  void setAllergiesOrMedicalNotes(String? v) => (v == null || v.trim().isEmpty)
      ? (state = state.copyWith(clearAllergies: true))
      : (state = state.copyWith(allergiesOrMedicalNotes: v));

  void toggleDiscipline(String id) {
    final current = Set<String>.from(state.selectedDisciplineIds);
    if (current.contains(id)) {
      current.remove(id);
    } else {
      current.add(id);
    }
    state = state.copyWith(selectedDisciplineIds: current.toList());
  }

  void setDataProcessingConsent(bool v) =>
      state = state.copyWith(dataProcessingConsent: v);
  void setPhotoVideoConsent(bool v) =>
      state = state.copyWith(photoVideoConsent: v);

  void setPin(String v) => state = state.copyWith(pin: v);
  void setConfirmPin(String v) => state = state.copyWith(confirmPin: v);

  void setError(String message) =>
      state = state.copyWith(errorMessage: message);

  void nextStep() {
    if (state.currentStep < SignUpState.totalSteps) {
      state = state.copyWith(
        currentStep: state.currentStep + 1,
        clearErrorMessage: true,
      );
    }
  }

  void prevStep() {
    if (state.currentStep > 1) {
      state = state.copyWith(
        currentStep: state.currentStep - 1,
        clearErrorMessage: true,
      );
    }
  }

  void goToStep(int step) =>
      state = state.copyWith(currentStep: step, clearErrorMessage: true);

  Future<void> submitRegistration() async {
    state = state.copyWith(isSubmitting: true, clearErrorMessage: true);
    try {
      final authRepo = ref.read(authRepositoryProvider);
      final profileRepo = ref.read(profileRepositoryProvider);
      final notifRepo = ref.read(notificationRepositoryProvider);
      final adminRepo = ref.read(adminUserRepositoryProvider);

      final uid = await authRepo.createUserWithoutSignIn(
        email: state.email.trim(),
        password: state.password,
      );

      final pinHash = sha256.convert(utf8.encode(state.pin)).toString();
      final now = DateTime.now();

      final profileTypes = state.hasJuniors
          ? [ProfileType.parentGuardian]
          : [ProfileType.adultStudent];

      final parentProfile = Profile(
        id: '',
        uid: uid,
        firstName: state.firstName.trim(),
        lastName: state.lastName.trim(),
        dateOfBirth: state.dateOfBirth!,
        profileTypes: profileTypes,
        gender: state.gender,
        addressLine1: state.addressLine1.trim(),
        addressLine2: state.addressLine2?.trim(),
        city: state.city.trim(),
        county: state.county.trim(),
        postcode: state.postcode.trim(),
        country: state.country,
        phone: state.phone.trim(),
        email: state.email.trim(),
        emergencyContactName: state.emergencyContactName.trim(),
        emergencyContactRelationship: state.emergencyContactRelationship.trim(),
        emergencyContactPhone: state.emergencyContactPhone.trim(),
        allergiesOrMedicalNotes: state.allergiesOrMedicalNotes?.trim(),
        photoVideoConsent: state.photoVideoConsent,
        dataProcessingConsent: true,
        dataProcessingConsentDate: now,
        dataProcessingConsentVersion: '1.0',
        selfRegistered: true,
        emailVerified: false,
        registrationStatus: RegistrationStatus.pendingVerification,
        registrationDate: now,
        isActive: true,
        pinHash: pinHash,
      );

      final parentId = await profileRepo.create(parentProfile);

      for (final child in state.children) {
        final childProfile = Profile(
          id: '',
          firstName: child.firstName.trim(),
          lastName: child.lastName.trim(),
          dateOfBirth: child.dateOfBirth!,
          profileTypes: [ProfileType.juniorStudent],
          gender: child.gender,
          addressLine1: state.addressLine1.trim(),
          addressLine2: state.addressLine2?.trim(),
          city: state.city.trim(),
          county: state.county.trim(),
          postcode: state.postcode.trim(),
          country: state.country,
          phone: state.phone.trim(),
          email: state.email.trim(),
          emergencyContactName:
              '${state.firstName.trim()} ${state.lastName.trim()}',
          emergencyContactRelationship: 'Parent/Guardian',
          emergencyContactPhone: state.phone.trim(),
          photoVideoConsent: state.photoVideoConsent,
          dataProcessingConsent: true,
          dataProcessingConsentDate: now,
          dataProcessingConsentVersion: '1.0',
          selfRegistered: true,
          registrationStatus: RegistrationStatus.pendingVerification,
          registrationDate: now,
          isActive: true,
          parentProfileId: parentId,
        );
        await profileRepo.create(childProfile);
      }

      final admins = await adminRepo.watchAll().first;
      final selectedIds = state.selectedDisciplineIds.toSet();

      for (final admin in admins) {
        if (!admin.isActive) continue;
        final shouldNotify =
            admin.isOwner ||
            admin.assignedDisciplineIds.any((id) => selectedIds.contains(id));
        if (!shouldNotify) continue;

        await notifRepo.create(
          NotificationLog(
            id: '',
            recipientProfileId: admin.firebaseUid,
            recipientType: RecipientType.admin,
            channel: NotificationChannel.push,
            type: NotificationType.selfRegistration,
            deliveryStatus: NotificationDeliveryStatus.sent,
            sentAt: now,
            title: 'New student registration',
            body:
                '${state.firstName.trim()} ${state.lastName.trim()} has registered',
            isRead: false,
          ),
        );
      }

      await authRepo.signIn(
        email: state.email.trim(),
        password: state.password,
      );
      await authRepo.sendEmailVerification();

      state = state.copyWith(isSubmitting: false, isComplete: true);
    } on AuthException catch (e) {
      state = state.copyWith(isSubmitting: false, errorMessage: e.message);
    } catch (_) {
      state = state.copyWith(
        isSubmitting: false,
        errorMessage: 'Registration failed. Please try again.',
      );
    }
  }
}

final signUpProvider =
    NotifierProvider.autoDispose<SignUpNotifier, SignUpState>(
      SignUpNotifier.new,
    );
