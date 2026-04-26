import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

import '../../domain/repositories/auth_repository.dart';

class FirebaseAuthRepository implements AuthRepository {
  FirebaseAuthRepository({FirebaseAuth? auth})
    : _auth = auth ?? FirebaseAuth.instance;

  final FirebaseAuth _auth;

  @override
  Stream<String?> watchAuthState() =>
      _auth.authStateChanges().map((user) => user?.uid);

  @override
  String? get currentUserId => _auth.currentUser?.uid;

  @override
  Future<void> signIn({required String email, required String password}) async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw AuthException(_friendlyMessage(e.code), code: e.code);
    }
  }

  @override
  Future<void> signOut() async {
    await _auth.signOut();
  }

  @override
  Future<void> sendPasswordReset({required String email}) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      throw AuthException(_friendlyMessage(e.code), code: e.code);
    }
  }

  @override
  Future<String> createUser({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      return credential.user!.uid;
    } on FirebaseAuthException catch (e) {
      throw AuthException(_friendlyMessage(e.code), code: e.code);
    }
  }

  @override
  Future<String> createUserWithoutSignIn({
    required String email,
    required String password,
  }) async {
    // Use a temporary secondary Firebase app so that creating the new account
    // does not displace the currently signed-in admin in the primary app.
    FirebaseApp? secondaryApp;
    try {
      secondaryApp = await Firebase.initializeApp(
        name: 'coach-creation-${DateTime.now().millisecondsSinceEpoch}',
        options: Firebase.app().options,
      );
      final secondaryAuth = FirebaseAuth.instanceFor(app: secondaryApp);
      final credential = await secondaryAuth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final uid = credential.user!.uid;
      await secondaryAuth.signOut();
      return uid;
    } on FirebaseAuthException catch (e) {
      throw AuthException(_friendlyMessage(e.code), code: e.code);
    } finally {
      await secondaryApp?.delete();
    }
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  String _friendlyMessage(String code) => switch (code) {
    'user-not-found' => 'No account found for that email address.',
    'wrong-password' => 'Incorrect password. Please try again.',
    'invalid-credential' => 'Incorrect email or password. Please try again.',
    'user-disabled' =>
      'This account has been disabled. Please contact support.',
    'too-many-requests' =>
      'Too many attempts. Please wait a moment and try again.',
    'network-request-failed' => 'Network error. Please check your connection.',
    _ => 'An error occurred. Please try again.',
  };
}
