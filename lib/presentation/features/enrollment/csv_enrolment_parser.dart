import '../../../domain/entities/discipline.dart';
import '../../../domain/entities/enrollment.dart';
import '../../../domain/entities/profile.dart';
import '../../../domain/entities/rank.dart';
import '../../../domain/use_cases/enrollment/enrol_student_use_case.dart';

/// Result of parsing and validating a single CSV row.
sealed class CsvRowResult {
  const CsvRowResult({required this.rowNumber, required this.rawName});
  final int rowNumber;
  final String rawName; // firstName + lastName from CSV (for display)
}

/// This row will create or reactivate an enrolment on confirm.
final class CsvRowSuccess extends CsvRowResult {
  const CsvRowSuccess({
    required super.rowNumber,
    required super.rawName,
    required this.profile,
    required this.discipline,
    required this.rank,
    required this.isReactivation,
    required this.existingEnrollment,
  });

  final Profile profile;
  final Discipline discipline;
  final Rank rank;

  /// True if the student has an existing inactive enrolment that will be
  /// reactivated rather than a new document being created.
  final bool isReactivation;
  final Enrollment? existingEnrollment;
}

/// This row was silently skipped (student already actively enrolled).
final class CsvRowSkipped extends CsvRowResult {
  const CsvRowSkipped({
    required super.rowNumber,
    required super.rawName,
    required this.disciplineName,
    required this.reason,
  });

  final String disciplineName;
  final String reason;
}

/// This row cannot be processed — shown in the errors section.
final class CsvRowError extends CsvRowResult {
  const CsvRowError({
    required super.rowNumber,
    required super.rawName,
    required this.reason,
  });

  final String reason;
}

/// Parsed and validated result for the entire CSV file.
class CsvParseResult {
  const CsvParseResult({
    required this.successes,
    required this.skipped,
    required this.errors,
  });

  final List<CsvRowSuccess> successes;
  final List<CsvRowSkipped> skipped;
  final List<CsvRowError> errors;

  bool get hasValidRows => successes.isNotEmpty;
}

/// Parses and validates a CSV file for bulk enrolment.
///
/// All validation is performed here, independent of UI, so the logic is
/// testable and reusable.
class CsvEnrolmentParser {
  const CsvEnrolmentParser({
    required this.profiles,
    required this.disciplines,
    required this.ranksByDiscipline,
    required this.activeEnrollmentsByStudent,
    required this.inactiveEnrollmentsByStudent,
  });

  /// All profiles in the system.
  final List<Profile> profiles;

  /// All active disciplines.
  final List<Discipline> disciplines;

  /// Ranks keyed by disciplineId.
  final Map<String, List<Rank>> ranksByDiscipline;

  /// Active enrollments keyed by studentId.
  final Map<String, List<Enrollment>> activeEnrollmentsByStudent;

  /// Inactive enrollments keyed by studentId.
  final Map<String, List<Enrollment>> inactiveEnrollmentsByStudent;

  /// Validates [rows] (each row is a map of column-name → value, header row
  /// already stripped). [preselectedDisciplineId] is non-null when the upload
  /// was launched from a Discipline Detail screen — in that case the
  /// `discipline` column in the CSV is ignored and this ID is used instead.
  CsvParseResult parse(
    List<Map<String, String>> rows, {
    String? preselectedDisciplineId,
  }) {
    final successes = <CsvRowSuccess>[];
    final skipped = <CsvRowSkipped>[];
    final errors = <CsvRowError>[];

    // Track processed student+discipline pairs to handle CSV duplicates
    final processed = <String>{};

    for (var i = 0; i < rows.length; i++) {
      final rowNum = i + 2; // 1-based, +1 for header row
      final row = rows[i];

      final firstName = (row['firstName'] ?? '').trim();
      final lastName = (row['lastName'] ?? '').trim();
      final dobRaw = (row['dateOfBirth'] ?? '').trim();
      final disciplineNameCsv = (row['discipline'] ?? '').trim();
      final rankNameCsv = (row['rank'] ?? '').trim();

      final displayName = '$firstName $lastName'.trim();

      // ── 1. Match profile ─────────────────────────────────────────────
      final dob = _parseDob(dobRaw);
      if (dob == null) {
        errors.add(
          CsvRowError(
            rowNumber: rowNum,
            rawName: displayName,
            reason:
                'Invalid date of birth format "$dobRaw". Expected DD/MM/YYYY.',
          ),
        );
        continue;
      }

      final profile = _findProfile(firstName, lastName, dob);
      if (profile == null) {
        errors.add(
          CsvRowError(
            rowNumber: rowNum,
            rawName: displayName,
            reason:
                'No profile found matching "$firstName $lastName" '
                '(DOB: $dobRaw).',
          ),
        );
        continue;
      }

      // ── 2. Resolve discipline ────────────────────────────────────────
      Discipline? discipline;
      if (preselectedDisciplineId != null) {
        try {
          discipline = disciplines.firstWhere(
            (d) => d.id == preselectedDisciplineId,
          );
        } catch (_) {
          errors.add(
            CsvRowError(
              rowNumber: rowNum,
              rawName: displayName,
              reason: 'Preselected discipline not found.',
            ),
          );
          continue;
        }
      } else {
        discipline = _findDiscipline(disciplineNameCsv);
        if (discipline == null) {
          errors.add(
            CsvRowError(
              rowNumber: rowNum,
              rawName: displayName,
              reason:
                  'Discipline "$disciplineNameCsv" not recognised or '
                  'inactive.',
            ),
          );
          continue;
        }
      }

      // ── 3. Age check ─────────────────────────────────────────────────
      final age = EnrolStudentUseCase.ageInYears(profile.dateOfBirth);
      if (age < 5) {
        errors.add(
          CsvRowError(
            rowNumber: rowNum,
            rawName: displayName,
            reason: 'Student is under the minimum age of 5.',
          ),
        );
        continue;
      }

      // ── 4. Duplicate detection ───────────────────────────────────────
      final dedupeKey = '${profile.id}:${discipline.id}';
      if (processed.contains(dedupeKey)) {
        skipped.add(
          CsvRowSkipped(
            rowNumber: rowNum,
            rawName: displayName,
            disciplineName: discipline.name,
            reason: 'Duplicate row — already processed in this file.',
          ),
        );
        continue;
      }

      // ── 5. Check active enrolment ────────────────────────────────────
      final activeEnrollments = activeEnrollmentsByStudent[profile.id] ?? [];
      final isActivelyEnrolled = activeEnrollments.any(
        (e) => e.disciplineId == discipline!.id,
      );
      if (isActivelyEnrolled) {
        skipped.add(
          CsvRowSkipped(
            rowNumber: rowNum,
            rawName: displayName,
            disciplineName: discipline.name,
            reason: 'Already enrolled — skipped.',
          ),
        );
        processed.add(dedupeKey);
        continue;
      }

      // ── 6. Resolve rank ──────────────────────────────────────────────
      final ranksForDiscipline = ranksByDiscipline[discipline.id] ?? [];
      if (ranksForDiscipline.isEmpty) {
        errors.add(
          CsvRowError(
            rowNumber: rowNum,
            rawName: displayName,
            reason: 'No ranks found for discipline "${discipline.name}".',
          ),
        );
        continue;
      }

      Rank rank;
      if (rankNameCsv.isEmpty) {
        // Default to bottom rank (last in displayOrder ascending list)
        rank = ranksForDiscipline.last;
      } else {
        final found = _findRank(ranksForDiscipline, rankNameCsv);
        if (found == null) {
          errors.add(
            CsvRowError(
              rowNumber: rowNum,
              rawName: displayName,
              reason:
                  'Rank "$rankNameCsv" not found in '
                  '"${discipline.name}".',
            ),
          );
          continue;
        }
        rank = found;
      }

      // ── 7. Check inactive enrolment (reactivation path) ─────────────
      final inactiveEnrollments =
          inactiveEnrollmentsByStudent[profile.id] ?? [];
      final existingInactive = inactiveEnrollments
          .where((e) => e.disciplineId == discipline!.id)
          .firstOrNull;

      processed.add(dedupeKey);
      successes.add(
        CsvRowSuccess(
          rowNumber: rowNum,
          rawName: displayName,
          profile: profile,
          discipline: discipline,
          rank: rank,
          isReactivation: existingInactive != null,
          existingEnrollment: existingInactive,
        ),
      );
    }

    return CsvParseResult(
      successes: successes,
      skipped: skipped,
      errors: errors,
    );
  }

  // ── Private helpers ──────────────────────────────────────────────────────

  DateTime? _parseDob(String raw) {
    // Expected format: DD/MM/YYYY
    final parts = raw.split('/');
    if (parts.length != 3) return null;
    final day = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    final year = int.tryParse(parts[2]);
    if (day == null || month == null || year == null) return null;
    try {
      return DateTime(year, month, day);
    } catch (_) {
      return null;
    }
  }

  Profile? _findProfile(String firstName, String lastName, DateTime dob) {
    for (final p in profiles) {
      if (p.firstName.toLowerCase() == firstName.toLowerCase() &&
          p.lastName.toLowerCase() == lastName.toLowerCase() &&
          _sameDob(p.dateOfBirth, dob)) {
        return p;
      }
    }
    return null;
  }

  bool _sameDob(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  Discipline? _findDiscipline(String name) {
    for (final d in disciplines) {
      if (d.name.toLowerCase() == name.toLowerCase()) return d;
    }
    return null;
  }

  Rank? _findRank(List<Rank> ranks, String name) {
    for (final r in ranks) {
      if (r.name.toLowerCase() == name.toLowerCase()) return r;
    }
    return null;
  }
}
