/// Authentication repository — admin app only.
///
/// Wraps Firebase Auth email/password sign-in.  The student app does not
/// use Firebase Auth; it uses the PIN-based [StudentSessionNotifier] instead.
abstract class AuthRepository {
  /// Emits the current Firebase user ID whenever auth state changes.
  /// Emits null when signed out.
  Stream<String?> watchAuthState();

  /// Returns the currently signed-in user's UID, or null if signed out.
  String? get currentUserId;

  /// Signs in with [email] and [password].
  /// Throws [AuthException] on failure.
  Future<void> signIn({required String email, required String password});

  /// Signs the current user out.
  Future<void> signOut();

  /// Sends a password-reset email to [email].
  Future<void> sendPasswordReset({required String email});

  /// Creates a new Firebase Auth account and returns the new user's UID.
  /// Used by the setup wizard to create the first owner account.
  /// Throws [AuthException] on failure.
  Future<String> createUser({required String email, required String password});

  /// Creates a new Firebase Auth account WITHOUT signing the new user in.
  /// Used when an already-authenticated admin creates a coach account —
  /// the admin's own session must not be displaced.
  /// Throws [AuthException] on failure.
  Future<String> createUserWithoutSignIn({
    required String email,
    required String password,
  });
}

/// Typed exception thrown by [AuthRepository] implementations.
class AuthException implements Exception {
  const AuthException(this.message, {this.code});

  final String message;

  /// Firebase error code, e.g. 'user-not-found', 'wrong-password'.
  final String? code;

  @override
  String toString() => 'AuthException(${code ?? ''}): $message';
}
