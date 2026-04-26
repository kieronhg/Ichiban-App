import 'dart:async';

import '../../domain/entities/enums.dart';
import '../../domain/entities/profile.dart';
import '../../domain/repositories/profile_repository.dart';

// Temporary in-memory profile repository for local UI testing.
// Replace with FirestoreProfileRepository once Firebase is configured.
//
// Test PIN for all profiles: 1234

final _mockProfiles = <Profile>[
  Profile(
    id: 'mock-student-1',
    firstName: 'James',
    lastName: 'Smith',
    dateOfBirth: DateTime(1995, 6, 15),
    profileTypes: const [ProfileType.adultStudent],
    addressLine1: '1 Test Street',
    city: 'London',
    county: 'Greater London',
    postcode: 'E1 1AA',
    country: 'United Kingdom',
    phone: '07700000001',
    email: 'james.smith@test.com',
    emergencyContactName: 'Jane Smith',
    emergencyContactRelationship: 'Spouse',
    emergencyContactPhone: '07700000002',
    photoVideoConsent: true,
    dataProcessingConsent: true,
    registrationDate: DateTime(2024, 1, 10),
    isActive: true,
    pinHash: '03ac674216f3e15c761ee1a5e255f067953623c8b388b4459e13f978d7c846f4',
  ),
  Profile(
    id: 'mock-student-2',
    firstName: 'Aisha',
    lastName: 'Khan',
    dateOfBirth: DateTime(2010, 3, 22),
    profileTypes: const [ProfileType.juniorStudent],
    addressLine1: '2 Test Avenue',
    city: 'Manchester',
    county: 'Greater Manchester',
    postcode: 'M1 2BB',
    country: 'United Kingdom',
    phone: '07700000003',
    email: 'aisha.khan@test.com',
    emergencyContactName: 'Omar Khan',
    emergencyContactRelationship: 'Father',
    emergencyContactPhone: '07700000004',
    photoVideoConsent: true,
    dataProcessingConsent: true,
    registrationDate: DateTime(2024, 2, 5),
    isActive: true,
    pinHash: '03ac674216f3e15c761ee1a5e255f067953623c8b388b4459e13f978d7c846f4',
  ),
  Profile(
    id: 'mock-student-3',
    firstName: 'Tom',
    lastName: 'Bradley',
    dateOfBirth: DateTime(1988, 11, 30),
    profileTypes: const [ProfileType.adultStudent],
    addressLine1: '3 Sample Road',
    city: 'Birmingham',
    county: 'West Midlands',
    postcode: 'B1 3CC',
    country: 'United Kingdom',
    phone: '07700000005',
    email: 'tom.bradley@test.com',
    emergencyContactName: 'Sarah Bradley',
    emergencyContactRelationship: 'Sister',
    emergencyContactPhone: '07700000006',
    photoVideoConsent: false,
    dataProcessingConsent: true,
    registrationDate: DateTime(2024, 3, 20),
    isActive: true,
    pinHash: '03ac674216f3e15c761ee1a5e255f067953623c8b388b4459e13f978d7c846f4',
  ),
];

class MockProfileRepository implements ProfileRepository {
  final _profiles = List<Profile>.from(_mockProfiles);
  final _controller = StreamController<List<Profile>>.broadcast();

  List<Profile> get _active => _profiles.where((p) => p.isActive).toList();

  void _notify() => _controller.add(List.of(_active));

  @override
  Future<Profile?> getById(String id) async =>
      _profiles.where((p) => p.id == id).firstOrNull;

  @override
  Future<List<Profile>> getAll() async => List.of(_active);

  @override
  Future<List<Profile>> getByType(ProfileType type) async =>
      _active.where((p) => p.profileTypes.contains(type)).toList();

  @override
  Future<List<Profile>> getJuniorsForParent(String parentProfileId) async =>
      _active.where((p) => p.parentProfileId == parentProfileId).toList();

  @override
  Future<String> create(Profile profile) async {
    final id = 'mock-${DateTime.now().millisecondsSinceEpoch}';
    _profiles.add(profile.copyWith(id: id));
    _notify();
    return id;
  }

  @override
  Future<void> update(Profile profile) async {
    final i = _profiles.indexWhere((p) => p.id == profile.id);
    if (i != -1) {
      _profiles[i] = profile;
      _notify();
    }
  }

  @override
  Future<void> deactivate(String id) async {
    final i = _profiles.indexWhere((p) => p.id == id);
    if (i != -1) {
      _profiles[i] = _profiles[i].copyWith(isActive: false);
      _notify();
    }
  }

  @override
  Future<void> resetPin(String id) async {
    final i = _profiles.indexWhere((p) => p.id == id);
    if (i != -1) {
      _profiles[i] = _profiles[i].copyWith(clearPinHash: true);
      _notify();
    }
  }

  @override
  Future<void> anonymise(String id) async {
    final i = _profiles.indexWhere((p) => p.id == id);
    if (i != -1) {
      _profiles[i] = _profiles[i].copyWith(
        firstName: 'Anonymised',
        lastName: 'User',
        isAnonymised: true,
        anonymisedAt: DateTime.now(),
      );
      _notify();
    }
  }

  @override
  Stream<List<Profile>> watchAll() async* {
    yield List.of(_active);
    yield* _controller.stream;
  }

  @override
  Stream<Profile?> watchById(String id) =>
      watchAll().map((list) => list.where((p) => p.id == id).firstOrNull);
}
