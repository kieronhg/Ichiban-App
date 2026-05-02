import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/profile.dart';
import 'admin_session_provider.dart';
import 'auth_providers.dart';
import 'repository_providers.dart';

// ── State ──────────────────────────────────────────────────────────────────

class StudentAuthState {
  const StudentAuthState({
    this.profile,
    this.isLoading = false,
    this.isEmailVerified = false,
  });

  final Profile? profile;
  final bool isLoading;
  final bool isEmailVerified;

  bool get isAuthenticated => profile != null;

  StudentAuthState copyWith({
    Profile? profile,
    bool? isLoading,
    bool? isEmailVerified,
  }) {
    return StudentAuthState(
      profile: profile ?? this.profile,
      isLoading: isLoading ?? this.isLoading,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
    );
  }
}

// ── Notifier ───────────────────────────────────────────────────────────────

class StudentAuthNotifier extends Notifier<StudentAuthState> {
  @override
  StudentAuthState build() {
    ref.listen<AsyncValue<String?>>(authStateProvider, (prev, next) {
      final uid = next.value;
      if (uid != null) {
        _loadProfile(uid);
      } else {
        state = const StudentAuthState();
      }
    });

    final uid = ref.read(authStateProvider).value;
    if (uid != null) {
      _loadProfile(uid);
    }

    return const StudentAuthState();
  }

  Future<void> _loadProfile(String uid) async {
    state = const StudentAuthState(isLoading: true);
    try {
      final profile = await ref.read(profileRepositoryProvider).findByUid(uid);
      if (profile == null) {
        state = const StudentAuthState();
        return;
      }
      final isVerified = ref.read(authRepositoryProvider).isEmailVerified;
      state = StudentAuthState(profile: profile, isEmailVerified: isVerified);
    } catch (_) {
      state = const StudentAuthState();
    }
  }

  /// Re-checks Firebase Auth email verification status without a full reload.
  Future<void> refreshEmailVerification() async {
    await ref.read(authRepositoryProvider).reloadUser();
    final isVerified = ref.read(authRepositoryProvider).isEmailVerified;
    if (state.profile != null) {
      state = state.copyWith(isEmailVerified: isVerified);
    }
  }

  Future<void> resendVerificationEmail() async {
    await ref.read(authRepositoryProvider).sendEmailVerification();
  }

  void signOut() {
    state = const StudentAuthState();
  }
}

final studentAuthProvider =
    NotifierProvider<StudentAuthNotifier, StudentAuthState>(
      StudentAuthNotifier.new,
    );

// ── Convenience providers ──────────────────────────────────────────────────

final currentStudentProfileProvider = Provider<Profile?>(
  (ref) => ref.watch(studentAuthProvider).profile,
);

final isStudentAuthenticatedProvider = Provider<bool>(
  (ref) => ref.watch(studentAuthProvider).isAuthenticated,
);

/// True when Firebase Auth has a UID but neither an admin session nor a
/// student profile was found. Triggers an "account not recognised" error
/// on the login screen and an automatic sign-out.
final isAccountUnrecognisedProvider = Provider<bool>((ref) {
  final authState = ref.watch(authStateProvider);
  if (authState.isLoading || authState.value == null) return false;

  final adminSession = ref.watch(adminSessionProvider);
  final studentAuth = ref.watch(studentAuthProvider);

  if (adminSession.isLoading || studentAuth.isLoading) return false;
  return !adminSession.isLoaded && !studentAuth.isAuthenticated;
});
