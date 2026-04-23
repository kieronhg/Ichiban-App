import 'package:flutter_test/flutter_test.dart';
import 'package:ichiban_app/core/providers/auth_providers.dart';

void main() {
  group('SignInState.copyWith', () {
    const populated = SignInState(
      isLoading: true,
      errorMessage: 'Server error',
      emailError: 'Bad email',
      passwordError: 'Too short',
      resetEmailSent: true,
    );

    // ── Preserve behaviour (argument omitted) ────────────────────────────

    test('preserves all values when called with no arguments', () {
      final result = populated.copyWith();
      expect(result.isLoading, true);
      expect(result.errorMessage, 'Server error');
      expect(result.emailError, 'Bad email');
      expect(result.passwordError, 'Too short');
      expect(result.resetEmailSent, true);
    });

    test('preserves errorMessage when argument is omitted', () {
      final result = populated.copyWith(isLoading: false);
      expect(result.errorMessage, 'Server error');
    });

    test('preserves emailError when argument is omitted', () {
      final result = populated.copyWith(isLoading: false);
      expect(result.emailError, 'Bad email');
    });

    test('preserves passwordError when argument is omitted', () {
      final result = populated.copyWith(isLoading: false);
      expect(result.passwordError, 'Too short');
    });

    // ── Clear behaviour (explicit null) ──────────────────────────────────

    test('clears errorMessage when null is passed explicitly', () {
      final result = populated.copyWith(errorMessage: null);
      expect(result.errorMessage, isNull);
      // Other fields unaffected
      expect(result.emailError, 'Bad email');
      expect(result.passwordError, 'Too short');
    });

    test('clears emailError when null is passed explicitly', () {
      final result = populated.copyWith(emailError: null);
      expect(result.emailError, isNull);
      expect(result.errorMessage, 'Server error');
    });

    test('clears passwordError when null is passed explicitly', () {
      final result = populated.copyWith(passwordError: null);
      expect(result.passwordError, isNull);
      expect(result.errorMessage, 'Server error');
    });

    // ── clearErrors smoke test ───────────────────────────────────────────

    test('clearErrors() clears all error fields and resets resetEmailSent', () {
      // Simulate what SignInNotifier.clearErrors() calls:
      final result = populated.copyWith(
        errorMessage: null,
        emailError: null,
        passwordError: null,
        resetEmailSent: false,
      );
      expect(result.errorMessage, isNull);
      expect(result.emailError, isNull);
      expect(result.passwordError, isNull);
      expect(result.resetEmailSent, false);
      // isLoading was true in populated and was not touched
      expect(result.isLoading, true);
    });

    // ── Update behaviour (non-null value) ────────────────────────────────

    test('updates errorMessage to a new non-null value', () {
      const base = SignInState(errorMessage: 'Old error');
      final result = base.copyWith(errorMessage: 'New error');
      expect(result.errorMessage, 'New error');
    });

    test('updates isLoading independently of nullable fields', () {
      final result = populated.copyWith(isLoading: false);
      expect(result.isLoading, false);
      expect(result.errorMessage, 'Server error');
    });
  });
}
