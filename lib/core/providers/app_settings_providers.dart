import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'repository_providers.dart';

// ── Privacy policy version ─────────────────────────────────────────────────

/// The current privacy policy version string stored in app settings.
/// Used when stamping [dataProcessingConsentVersion] on new profiles.
/// Falls back to '1.0' if the setting has not been seeded yet.
final privacyPolicyVersionProvider = FutureProvider<String>((ref) async {
  final setting = await ref
      .watch(appSettingsRepositoryProvider)
      .get('privacyPolicyVersion');
  return setting?.stringValue ?? '1.0';
});
