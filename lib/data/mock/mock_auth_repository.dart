import 'dart:async';

import '../../domain/repositories/auth_repository.dart';

// Temporary stand-in for FirebaseAuthRepository while Firebase is not yet
// configured. Accepts one hardcoded admin account for local UI testing.
// Replace with FirebaseAuthRepository once flutterfire configure has been run.
const _testEmail = 'admin@test.com';
const _testPassword = 'admin123';
const _fakeUid = 'mock-admin-uid';

class MockAuthRepository implements AuthRepository {
  final _controller = StreamController<String?>.broadcast();
  String? _currentUid;

  @override
  Stream<String?> watchAuthState() async* {
    yield _currentUid;
    yield* _controller.stream;
  }

  @override
  String? get currentUserId => _currentUid;

  @override
  Future<void> signIn({required String email, required String password}) async {
    await Future.delayed(const Duration(milliseconds: 500));
    if (email.trim() == _testEmail && password == _testPassword) {
      _currentUid = _fakeUid;
      _controller.add(_fakeUid);
    } else {
      throw const AuthException(
        'Invalid email or password.',
        code: 'wrong-password',
      );
    }
  }

  @override
  Future<void> signOut() async {
    _currentUid = null;
    _controller.add(null);
  }

  @override
  Future<void> sendPasswordReset({required String email}) async {
    // No-op in mock — just silently succeed.
  }

  @override
  Future<String> createUser({
    required String email,
    required String password,
  }) async {
    // Mock: return a fake UID.
    return 'mock-created-uid';
  }

  @override
  Future<String> createUserWithoutSignIn({
    required String email,
    required String password,
  }) async {
    // Mock: return a fake UID without touching current session.
    return 'mock-created-uid-${email.hashCode}';
  }
}
