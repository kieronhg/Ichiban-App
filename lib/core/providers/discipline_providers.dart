import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/discipline.dart';
import '../../domain/entities/enums.dart';
import '../../domain/entities/rank.dart';
import '../../domain/use_cases/discipline/create_discipline_use_case.dart';
import '../../domain/use_cases/discipline/get_discipline_use_case.dart';
import '../../domain/use_cases/discipline/get_disciplines_use_case.dart';
import '../../domain/use_cases/discipline/update_discipline_use_case.dart';
import '../../domain/use_cases/rank/create_rank_use_case.dart';
import '../../domain/use_cases/rank/delete_rank_use_case.dart';
import '../../domain/use_cases/rank/get_ranks_use_case.dart';
import '../../domain/use_cases/rank/reorder_ranks_use_case.dart';
import '../../domain/use_cases/rank/update_rank_use_case.dart';
import 'auth_providers.dart';
import 'repository_providers.dart';

// ── Use-case providers ─────────────────────────────────────────────────────

final getDisciplinesUseCaseProvider = Provider<GetDisciplinesUseCase>(
  (ref) => GetDisciplinesUseCase(ref.watch(disciplineRepositoryProvider)),
);

final getDisciplineUseCaseProvider = Provider<GetDisciplineUseCase>(
  (ref) => GetDisciplineUseCase(ref.watch(disciplineRepositoryProvider)),
);

final createDisciplineUseCaseProvider = Provider<CreateDisciplineUseCase>(
  (ref) => CreateDisciplineUseCase(ref.watch(disciplineRepositoryProvider)),
);

final updateDisciplineUseCaseProvider = Provider<UpdateDisciplineUseCase>(
  (ref) => UpdateDisciplineUseCase(ref.watch(disciplineRepositoryProvider)),
);

final getRanksUseCaseProvider = Provider<GetRanksUseCase>(
  (ref) => GetRanksUseCase(ref.watch(rankRepositoryProvider)),
);

final createRankUseCaseProvider = Provider<CreateRankUseCase>(
  (ref) => CreateRankUseCase(ref.watch(rankRepositoryProvider)),
);

final updateRankUseCaseProvider = Provider<UpdateRankUseCase>(
  (ref) => UpdateRankUseCase(ref.watch(rankRepositoryProvider)),
);

final deleteRankUseCaseProvider = Provider<DeleteRankUseCase>(
  (ref) => DeleteRankUseCase(ref.watch(rankRepositoryProvider)),
);

final reorderRanksUseCaseProvider = Provider<ReorderRanksUseCase>(
  (ref) => ReorderRanksUseCase(ref.watch(rankRepositoryProvider)),
);

// ── Stream providers ───────────────────────────────────────────────────────

/// All disciplines (active and inactive), live.
/// Used by admin list and detail screens.
final disciplineListProvider = StreamProvider<List<Discipline>>(
  (ref) => ref.watch(getDisciplinesUseCaseProvider).watchAll(),
);

/// Active disciplines only, live.
/// Used by student-facing screens and new-enrolment flows.
final activeDisciplineListProvider = StreamProvider<List<Discipline>>(
  (ref) => ref.watch(getDisciplinesUseCaseProvider).watchActive(),
);

/// Single discipline by ID, live. Emits null if not found.
/// Derived from the all-disciplines stream to avoid an extra Firestore
/// listener per detail screen.
final disciplineProvider = StreamProvider.family<Discipline?, String>(
  (ref, id) => ref.watch(disciplineListProvider.stream).map(
        (list) => list.where((d) => d.id == id).firstOrNull,
      ),
);

/// All ranks for a discipline, ordered by displayOrder ascending, live.
final rankListProvider =
    StreamProvider.family<List<Rank>, String>(
  (ref, disciplineId) =>
      ref.watch(getRanksUseCaseProvider).watchForDiscipline(disciplineId),
);

// ── Discipline form notifier ───────────────────────────────────────────────

/// Manages create/edit state for a [Discipline].
///
/// For **create**: leave form at its empty default state and call [save].
/// For **edit**: call [load] with the existing [Discipline] first, then [save].
class DisciplineFormNotifier extends Notifier<DisciplineFormState> {
  @override
  DisciplineFormState build() => DisciplineFormState.empty();

  void load(Discipline discipline) =>
      state = DisciplineFormState.fromDiscipline(discipline);

  void setName(String v) => state = state.copyWith(name: v);
  void setDescription(String? v) => state = state.copyWith(description: v);
  void setActive(bool v) => state = state.copyWith(isActive: v);

  /// Creates or updates the discipline. Returns the discipline ID.
  Future<String> save() async {
    state = state.copyWith(isSaving: true, errorMessage: null);
    try {
      final adminId = ref.read(currentAdminIdProvider) ?? '';
      final discipline = state.toDiscipline(adminId: adminId);
      final String id;
      if (discipline.id.isEmpty) {
        id = await ref.read(createDisciplineUseCaseProvider)(discipline);
      } else {
        await ref.read(updateDisciplineUseCaseProvider)(discipline);
        id = discipline.id;
      }
      state = state.copyWith(isSaving: false);
      return id;
    } catch (e) {
      state = state.copyWith(isSaving: false, errorMessage: e.toString());
      rethrow;
    }
  }
}

final disciplineFormNotifierProvider =
    NotifierProvider.autoDispose<DisciplineFormNotifier, DisciplineFormState>(
  DisciplineFormNotifier.new,
);

// ── Discipline form state ──────────────────────────────────────────────────

class DisciplineFormState {
  const DisciplineFormState({
    required this.id,
    required this.name,
    required this.description,
    required this.isActive,
    required this.isSaving,
    required this.errorMessage,
  });

  final String id;
  final String name;
  final String? description;
  final bool isActive;
  final bool isSaving;
  final String? errorMessage;

  bool get isEditing => id.isNotEmpty;

  factory DisciplineFormState.empty() => const DisciplineFormState(
        id: '',
        name: '',
        description: null,
        isActive: true,
        isSaving: false,
        errorMessage: null,
      );

  factory DisciplineFormState.fromDiscipline(Discipline d) =>
      DisciplineFormState(
        id: d.id,
        name: d.name,
        description: d.description,
        isActive: d.isActive,
        isSaving: false,
        errorMessage: null,
      );

  /// Converts form state back to a [Discipline] for persistence.
  /// An empty [id] signals a new discipline — Firestore will generate one.
  Discipline toDiscipline({required String adminId}) => Discipline(
        id: id,
        name: name.trim(),
        description: description?.trim().isEmpty == true
            ? null
            : description?.trim(),
        isActive: isActive,
        createdByAdminId: adminId,
        createdAt: DateTime.now(), // will be stamped by use case on create
      );

  DisciplineFormState copyWith({
    String? id,
    String? name,
    String? description,
    bool? isActive,
    bool? isSaving,
    String? errorMessage,
  }) {
    return DisciplineFormState(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      isActive: isActive ?? this.isActive,
      isSaving: isSaving ?? this.isSaving,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

// ── Rank form notifier ─────────────────────────────────────────────────────

/// Manages create/edit state for a [Rank] within a discipline.
///
/// For **create**: call [init] with the [disciplineId] and the next
/// [displayOrder] value, then call [save].
/// For **edit**: call [load] with the existing [Rank], then [save].
class RankFormNotifier extends Notifier<RankFormState> {
  @override
  RankFormState build() => RankFormState.empty();

  /// Prepares the form for creating a new rank inside [disciplineId].
  /// [nextDisplayOrder] is typically `existingRanks.length + 1`.
  void init({required String disciplineId, required int nextDisplayOrder}) {
    state = RankFormState.empty().copyWith(
      disciplineId: disciplineId,
      displayOrder: nextDisplayOrder,
    );
  }

  void load(Rank rank) => state = RankFormState.fromRank(rank);

  void setName(String v) => state = state.copyWith(name: v);
  void setColourHex(String? v) => state = state.copyWith(colourHex: v);
  void setRankType(RankType v) => state = state.copyWith(rankType: v);
  void setMonCount(int? v) => state = state.copyWith(monCount: v);
  void setMinAttendanceForGrading(int? v) =>
      state = state.copyWith(minAttendanceForGrading: v);

  /// Creates or updates the rank. Returns the rank ID.
  Future<String> save() async {
    state = state.copyWith(isSaving: true, errorMessage: null);
    try {
      final rank = state.toRank();
      final String id;
      if (rank.id.isEmpty) {
        id = await ref.read(createRankUseCaseProvider)(rank);
      } else {
        await ref.read(updateRankUseCaseProvider)(rank);
        id = rank.id;
      }
      state = state.copyWith(isSaving: false);
      return id;
    } catch (e) {
      state = state.copyWith(isSaving: false, errorMessage: e.toString());
      rethrow;
    }
  }
}

final rankFormNotifierProvider =
    NotifierProvider.autoDispose<RankFormNotifier, RankFormState>(
  RankFormNotifier.new,
);

// ── Rank form state ────────────────────────────────────────────────────────

/// Sentinel used in [RankFormState.copyWith] to distinguish "pass null to
/// clear this field" from "leave this field unchanged".
const _absent = Object();

class RankFormState {
  const RankFormState({
    required this.id,
    required this.disciplineId,
    required this.name,
    required this.colourHex,
    required this.rankType,
    required this.monCount,
    required this.minAttendanceForGrading,
    required this.displayOrder,
    required this.isSaving,
    required this.errorMessage,
  });

  final String id;
  final String disciplineId;
  final String name;
  final String? colourHex;
  final RankType rankType;
  final int? monCount;
  final int? minAttendanceForGrading;
  final int displayOrder;
  final bool isSaving;
  final String? errorMessage;

  bool get isEditing => id.isNotEmpty;

  factory RankFormState.empty() => const RankFormState(
        id: '',
        disciplineId: '',
        name: '',
        colourHex: null,
        rankType: RankType.kyu,
        monCount: null,
        minAttendanceForGrading: null,
        displayOrder: 0,
        isSaving: false,
        errorMessage: null,
      );

  factory RankFormState.fromRank(Rank r) => RankFormState(
        id: r.id,
        disciplineId: r.disciplineId,
        name: r.name,
        colourHex: r.colourHex,
        rankType: r.rankType,
        monCount: r.monCount,
        minAttendanceForGrading: r.minAttendanceForGrading,
        displayOrder: r.displayOrder,
        isSaving: false,
        errorMessage: null,
      );

  /// Converts form state back to a [Rank] for persistence.
  /// An empty [id] signals a new rank — Firestore will generate one.
  Rank toRank() => Rank(
        id: id,
        disciplineId: disciplineId,
        name: name.trim(),
        displayOrder: displayOrder,
        colourHex: colourHex?.trim().isEmpty == true ? null : colourHex?.trim(),
        rankType: rankType,
        monCount: monCount,
        minAttendanceForGrading: minAttendanceForGrading,
        createdAt: DateTime.now(), // will be stamped by use case on create
      );

  /// Nullable int fields ([monCount], [minAttendanceForGrading]) accept
  /// [_absent] as a sentinel meaning "keep existing value".  Passing `null`
  /// explicitly clears the field, which is needed when an admin empties an
  /// optional int field in the form.
  RankFormState copyWith({
    String? id,
    String? disciplineId,
    String? name,
    String? colourHex,
    RankType? rankType,
    Object? monCount = _absent,
    Object? minAttendanceForGrading = _absent,
    int? displayOrder,
    bool? isSaving,
    String? errorMessage,
  }) {
    return RankFormState(
      id: id ?? this.id,
      disciplineId: disciplineId ?? this.disciplineId,
      name: name ?? this.name,
      colourHex: colourHex ?? this.colourHex,
      rankType: rankType ?? this.rankType,
      monCount: monCount == _absent ? this.monCount : monCount as int?,
      minAttendanceForGrading: minAttendanceForGrading == _absent
          ? this.minAttendanceForGrading
          : minAttendanceForGrading as int?,
      displayOrder: displayOrder ?? this.displayOrder,
      isSaving: isSaving ?? this.isSaving,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}
