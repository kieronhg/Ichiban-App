import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/repositories/auth_repository.dart';
import 'repository_providers.dart';

// Sentinel that distinguishes "argument omitted" from "argument passed as null"
// in copyWith. Using identical() instead of == avoids any risk of a custom
// operator overriding the comparison.
const _absent = Object();

// ── Auth state ─────────────────────────────────────────────────────────────

/// Emits the current admin UID whenever Firebase auth state changes.
/// Emits null when signed out.
final authStateProvider = StreamProvider<String?>(
  (ref) => ref.watch(authRepositoryProvider).watchAuthState(),
);

/// True when an admin is signed in.
final isAdminAuthenticatedProvider = Provider<bool>(
  (ref) => ref.watch(authStateProvider).value != null,
);

/// The current admin's Firebase UID, or null if signed out.
/// Use this wherever an admin actor ID is needed (replaces kAdminPlaceholderId).
final currentAdminIdProvider = Provider<String?>(
  (ref) => ref.watch(authStateProvider).value,
);

// ── Sign-in notifier ───────────────────────────────────────────────────────

class SignInNotifier extends Notifier<SignInState> {
  @override
  SignInState build() => const SignInState();

  Future<void> signIn({required String email, required String password}) async {
    if (email.trim().isEmpty) {
      state = state.copyWith(emailError: 'Email is required.');
      return;
    }
    if (password.isEmpty) {
      state = state.copyWith(passwordError: 'Password is required.');
      return;
    }

    state = state.copyWith(
      isLoading: true,
      errorMessage: null,
      emailError: null,
      passwordError: null,
    );

    try {
      await ref
          .read(authRepositoryProvider)
          .signIn(email: email, password: password);
      state = state.copyWith(isLoading: false);
    } on AuthException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.message);
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'An unexpected error occurred. Please try again.',
      );
    }
  }

  Future<void> sendPasswordReset({required String email}) async {
    if (email.trim().isEmpty) {
      state = state.copyWith(emailError: 'Enter your email address first.');
      return;
    }
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      await ref.read(authRepositoryProvider).sendPasswordReset(email: email);
      state = state.copyWith(
        isLoading: false,
        errorMessage: null,
        resetEmailSent: true,
      );
    } on AuthException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.message);
    }
  }

  void clearErrors() => state = state.copyWith(
    errorMessage: null,
    emailError: null,
    passwordError: null,
    resetEmailSent: false,
  );
}

final signInNotifierProvider =
    NotifierProvider.autoDispose<SignInNotifier, SignInState>(
      SignInNotifier.new,
    );

// ── Sign-out ───────────────────────────────────────────────────────────────

/// Call ref.read(signOutProvider)() to sign the admin out.
final signOutProvider = Provider<Future<void> Function()>(
  (ref) =>
      () => ref.read(authRepositoryProvider).signOut(),
);

// ── Sign-in state ──────────────────────────────────────────────────────────

class SignInState {
  const SignInState({
    this.isLoading = false,
    this.errorMessage,
    this.emailError,
    this.passwordError,
    this.resetEmailSent = false,
  });

  final bool isLoading;
  final String? errorMessage;
  final String? emailError;
  final String? passwordError;
  final bool resetEmailSent;

  SignInState copyWith({
    bool? isLoading,
    // Nullable fields use Object? + _absent sentinel so callers can explicitly
    // pass null to clear the field. Omitting the argument preserves the current
    // value; passing null clears it.
    Object? errorMessage = _absent,
    Object? emailError = _absent,
    Object? passwordError = _absent,
    bool? resetEmailSent,
  }) {
    return SignInState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: identical(errorMessage, _absent)
          ? this.errorMessage
          : errorMessage as String?,
      emailError: identical(emailError, _absent)
          ? this.emailError
          : emailError as String?,
      passwordError: identical(passwordError, _absent)
          ? this.passwordError
          : passwordError as String?,
      resetEmailSent: resetEmailSent ?? this.resetEmailSent,
    );
  }
}
