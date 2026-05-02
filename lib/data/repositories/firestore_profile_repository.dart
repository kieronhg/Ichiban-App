import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/profile.dart';
import '../../domain/entities/enums.dart';
import '../../domain/repositories/profile_repository.dart';
import '../firebase/firestore_collections.dart';

class FirestoreProfileRepository implements ProfileRepository {
  @override
  Future<Profile?> getById(String id) async {
    final snap = await FirestoreCollections.profiles().doc(id).get();
    return snap.data();
  }

  @override
  Future<Profile?> findByUid(String uid) async {
    final snap = await FirestoreCollections.profiles()
        .where('uid', isEqualTo: uid)
        .limit(1)
        .get();
    return snap.docs.isEmpty ? null : snap.docs.first.data();
  }

  @override
  Future<Profile?> findByEmail(String email) async {
    final snap = await FirestoreCollections.profiles()
        .where('email', isEqualTo: email)
        .limit(1)
        .get();
    return snap.docs.isEmpty ? null : snap.docs.first.data();
  }

  @override
  Future<List<Profile>> getAll() async {
    final snap = await FirestoreCollections.profiles().get();
    return snap.docs.map((d) => d.data()).toList();
  }

  @override
  Future<List<Profile>> getByType(ProfileType type) async {
    final snap = await FirestoreCollections.profiles()
        .where('profileTypes', arrayContains: type.name)
        .get();
    return snap.docs.map((d) => d.data()).toList();
  }

  @override
  Future<List<Profile>> getJuniorsForParent(String parentProfileId) async {
    final snap = await FirestoreCollections.profiles()
        .where('parentProfileId', isEqualTo: parentProfileId)
        .get();
    return snap.docs.map((d) => d.data()).toList();
  }

  @override
  Future<String> create(Profile profile) async {
    final ref = await FirestoreCollections.profiles().add(profile);
    return ref.id;
  }

  @override
  Future<void> update(Profile profile) async {
    await FirestoreCollections.profiles().doc(profile.id).set(profile);
  }

  @override
  Future<void> deactivate(String id) async {
    await FirestoreCollections.profiles().doc(id).update({'isActive': false});
  }

  @override
  Future<void> updateInviteStatus({
    required String id,
    required InviteStatus status,
    DateTime? sentAt,
    DateTime? expiresAt,
    int? resendCount,
  }) async {
    final data = <String, dynamic>{'inviteStatus': status.name};
    if (sentAt != null) data['inviteSentAt'] = Timestamp.fromDate(sentAt);
    if (expiresAt != null) {
      data['inviteExpiresAt'] = Timestamp.fromDate(expiresAt);
    }
    if (resendCount != null) data['inviteResendCount'] = resendCount;
    await FirestoreCollections.profiles().doc(id).update(data);
  }

  @override
  Future<List<Profile>> getPendingInvites() async {
    final snap = await FirestoreCollections.profiles()
        .where('inviteStatus', isEqualTo: InviteStatus.pending.name)
        .get();
    return snap.docs.map((d) => d.data()).toList();
  }

  @override
  Stream<List<Profile>> watchAll() {
    return FirestoreCollections.profiles().snapshots().map(
      (snap) => snap.docs.map((d) => d.data()).toList(),
    );
  }

  @override
  Stream<List<Profile>> watchPendingInvites() {
    return FirestoreCollections.profiles()
        .where('inviteStatus', isEqualTo: InviteStatus.pending.name)
        .snapshots()
        .map((snap) => snap.docs.map((d) => d.data()).toList());
  }

  @override
  Stream<Profile?> watchById(String id) {
    return FirestoreCollections.profiles()
        .doc(id)
        .snapshots()
        .map((snap) => snap.data());
  }

  /// Replaces all personal data fields with anonymisation placeholders and
  /// marks the profile as anonymised.
  ///
  /// Required String fields are set to '[Anonymised]' so the document remains
  /// readable by [ProfileConverter.fromMap] without schema changes.
  /// Nullable fields are set to null.
  /// [dateOfBirth] is set to the Unix epoch (1970-01-01) as a safe placeholder.
  @override
  Future<void> resetPin(String id) async {
    await FirestoreCollections.profiles().doc(id).update({'pinHash': null});
  }

  @override
  Future<void> flagAllActiveForReConsent() async {
    final snap = await FirestoreCollections.profiles()
        .where('isActive', isEqualTo: true)
        .where('isAnonymised', isEqualTo: false)
        .get();

    final db = FirebaseFirestore.instance;
    final batches = <WriteBatch>[];
    var current = db.batch();
    var count = 0;

    for (final doc in snap.docs) {
      current.update(db.collection('profiles').doc(doc.id), {
        'requiresReConsent': true,
      });
      count++;
      // Firestore batches are limited to 500 operations
      if (count == 500) {
        batches.add(current);
        current = db.batch();
        count = 0;
      }
    }
    if (count > 0) batches.add(current);

    for (final batch in batches) {
      await batch.commit();
    }
  }

  @override
  Future<void> anonymise(String id) async {
    await FirestoreCollections.profiles().doc(id).update({
      // Required String fields — replaced with placeholder
      'firstName': '[Anonymised]',
      'lastName': '[Anonymised]',
      'addressLine1': '[Anonymised]',
      'city': '[Anonymised]',
      'county': '[Anonymised]',
      'postcode': '[Anonymised]',
      'country': '[Anonymised]',
      'phone': '[Anonymised]',
      'email': '[Anonymised]',
      'emergencyContactName': '[Anonymised]',
      'emergencyContactRelationship': '[Anonymised]',
      'emergencyContactPhone': '[Anonymised]',
      // Required date — replaced with epoch placeholder
      'dateOfBirth': Timestamp.fromDate(DateTime.utc(1970)),
      // Nullable fields — wiped to null
      'addressLine2': null,
      'gender': null,
      'allergiesOrMedicalNotes': null,
      'pinHash': null,
      'fcmToken': null,
      // Anonymisation flags
      'isAnonymised': true,
      'anonymisedAt': Timestamp.now(),
    });
  }
}
