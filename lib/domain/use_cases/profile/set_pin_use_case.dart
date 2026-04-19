import 'dart:convert';
import 'package:crypto/crypto.dart';
import '../../repositories/profile_repository.dart';

class SetPinUseCase {
  const SetPinUseCase(this._repo);

  final ProfileRepository _repo;

  /// Validates [pin], hashes it with SHA-256, and stores the hash on the
  /// profile. The raw PIN is never persisted.
  ///
  /// [pin] must be exactly 4 numeric digits.
  Future<void> call({required String profileId, required String pin}) async {
    if (!RegExp(r'^\d{4}$').hasMatch(pin)) {
      throw ArgumentError('PIN must be exactly 4 numeric digits.');
    }

    final profile = await _repo.getById(profileId);
    if (profile == null) {
      throw ArgumentError('Profile not found: $profileId');
    }

    final pinHash = sha256.convert(utf8.encode(pin)).toString();
    await _repo.update(profile.copyWith(pinHash: pinHash));
  }

  /// Returns true if [pin] matches the stored hash for [profileId].
  Future<bool> verify({required String profileId, required String pin}) async {
    final profile = await _repo.getById(profileId);
    if (profile == null || profile.pinHash == null) return false;
    final hash = sha256.convert(utf8.encode(pin)).toString();
    return hash == profile.pinHash;
  }
}
