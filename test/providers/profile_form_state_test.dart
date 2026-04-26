import 'package:flutter_test/flutter_test.dart';
import 'package:ichiban_app/core/providers/profile_providers.dart';
import 'package:ichiban_app/domain/entities/enums.dart';

void main() {
  group('ProfileFormState.copyWith', () {
    // A fully-populated state to test preservation and clearing against.
    final populated = ProfileFormState.empty().copyWith(
      id: 'abc',
      firstName: 'Jane',
      lastName: 'Doe',
      gender: 'Female',
      addressLine2: 'Flat 1',
      allergiesOrMedicalNotes: 'Peanut allergy',
      notes: 'Prefers morning classes',
      parentProfileId: 'parent-1',
      secondParentProfileId: 'parent-2',
      payingParentId: 'parent-1',
      dataProcessingConsentVersion: 'v1.2',
      registrationDate: DateTime(2023, 1, 1),
      errorMessage: 'Save failed',
    );

    // ── Preserve behaviour (argument omitted) ────────────────────────────

    test('preserves all nullable fields when called with no arguments', () {
      final result = populated.copyWith();
      expect(result.gender, 'Female');
      expect(result.addressLine2, 'Flat 1');
      expect(result.allergiesOrMedicalNotes, 'Peanut allergy');
      expect(result.notes, 'Prefers morning classes');
      expect(result.parentProfileId, 'parent-1');
      expect(result.secondParentProfileId, 'parent-2');
      expect(result.payingParentId, 'parent-1');
      expect(result.dataProcessingConsentVersion, 'v1.2');
      expect(result.registrationDate, DateTime(2023, 1, 1));
      expect(result.errorMessage, 'Save failed');
    });

    test('preserves non-nullable fields when called with no arguments', () {
      final result = populated.copyWith();
      expect(result.id, 'abc');
      expect(result.firstName, 'Jane');
      expect(result.lastName, 'Doe');
    });

    // ── Clear behaviour (explicit null) ──────────────────────────────────

    test('clears gender when null is passed explicitly', () {
      final result = populated.copyWith(gender: null);
      expect(result.gender, isNull);
      expect(result.notes, 'Prefers morning classes'); // others unaffected
    });

    test('clears addressLine2 when null is passed explicitly', () {
      final result = populated.copyWith(addressLine2: null);
      expect(result.addressLine2, isNull);
    });

    test('clears allergiesOrMedicalNotes when null is passed explicitly', () {
      final result = populated.copyWith(allergiesOrMedicalNotes: null);
      expect(result.allergiesOrMedicalNotes, isNull);
    });

    test('clears notes when null is passed explicitly', () {
      final result = populated.copyWith(notes: null);
      expect(result.notes, isNull);
    });

    test('clears parentProfileId when null is passed explicitly', () {
      final result = populated.copyWith(parentProfileId: null);
      expect(result.parentProfileId, isNull);
      expect(result.secondParentProfileId, 'parent-2'); // unaffected
    });

    test('clears secondParentProfileId when null is passed explicitly', () {
      final result = populated.copyWith(secondParentProfileId: null);
      expect(result.secondParentProfileId, isNull);
    });

    test('clears payingParentId when null is passed explicitly', () {
      final result = populated.copyWith(payingParentId: null);
      expect(result.payingParentId, isNull);
    });

    test(
      'clears dataProcessingConsentVersion when null is passed explicitly',
      () {
        final result = populated.copyWith(dataProcessingConsentVersion: null);
        expect(result.dataProcessingConsentVersion, isNull);
      },
    );

    test('clears registrationDate when null is passed explicitly', () {
      final result = populated.copyWith(registrationDate: null);
      expect(result.registrationDate, isNull);
    });

    test('clears errorMessage when null is passed explicitly', () {
      final result = populated.copyWith(errorMessage: null);
      expect(result.errorMessage, isNull);
      expect(result.notes, 'Prefers morning classes'); // unaffected
    });

    // ── Update behaviour (new non-null value) ────────────────────────────

    test('updates notes to a new value', () {
      final result = populated.copyWith(notes: 'Evening only');
      expect(result.notes, 'Evening only');
    });

    test('updates gender to a new value', () {
      final result = populated.copyWith(gender: 'Male');
      expect(result.gender, 'Male');
    });

    test('updates firstName without affecting nullable fields', () {
      final result = populated.copyWith(firstName: 'John');
      expect(result.firstName, 'John');
      expect(result.gender, 'Female');
      expect(result.notes, 'Prefers morning classes');
      expect(result.parentProfileId, 'parent-1');
    });

    // ── ProfileType list field ───────────────────────────────────────────

    test('updates profileTypes list', () {
      final result = populated.copyWith(
        profileTypes: [ProfileType.adultStudent],
      );
      expect(result.profileTypes, [ProfileType.adultStudent]);
    });

    // ── isSaving / errorMessage during save cycle ────────────────────────

    test('save-start: sets isSaving=true and clears errorMessage', () {
      final withError = populated.copyWith(errorMessage: 'Previous error');
      final saving = withError.copyWith(isSaving: true, errorMessage: null);
      expect(saving.isSaving, true);
      expect(saving.errorMessage, isNull);
      expect(saving.notes, 'Prefers morning classes'); // state preserved
    });

    test('save-end: sets isSaving=false without touching other fields', () {
      final saving = populated.copyWith(isSaving: true);
      final done = saving.copyWith(isSaving: false);
      expect(done.isSaving, false);
      expect(done.notes, 'Prefers morning classes');
      expect(done.gender, 'Female');
    });
  });
}
