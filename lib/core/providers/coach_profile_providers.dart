import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/coach_profile.dart';
import '../../domain/use_cases/coach/coach_update_dbs_use_case.dart';
import '../../domain/use_cases/coach/coach_update_first_aid_use_case.dart';
import '../../domain/use_cases/coach/create_coach_profile_use_case.dart';
import '../../domain/use_cases/coach/get_coach_profile_use_case.dart';
import '../../domain/use_cases/coach/owner_update_coach_compliance_use_case.dart';
import '../../domain/use_cases/coach/update_coach_personal_details_use_case.dart';
import '../../domain/use_cases/coach/verify_coach_compliance_use_case.dart';
import 'repository_providers.dart';

// ── Use case providers ─────────────────────────────────────────────────────

final getCoachProfileUseCaseProvider = Provider<GetCoachProfileUseCase>(
  (ref) => GetCoachProfileUseCase(ref.watch(coachProfileRepositoryProvider)),
);

final createCoachProfileUseCaseProvider = Provider<CreateCoachProfileUseCase>(
  (ref) => CreateCoachProfileUseCase(ref.watch(coachProfileRepositoryProvider)),
);

final updateCoachPersonalDetailsUseCaseProvider =
    Provider<UpdateCoachPersonalDetailsUseCase>(
      (ref) => UpdateCoachPersonalDetailsUseCase(
        ref.watch(coachProfileRepositoryProvider),
        ref.watch(adminUserRepositoryProvider),
      ),
    );

final coachUpdateDbsUseCaseProvider = Provider<CoachUpdateDbsUseCase>(
  (ref) => CoachUpdateDbsUseCase(ref.watch(coachProfileRepositoryProvider)),
);

final coachUpdateFirstAidUseCaseProvider = Provider<CoachUpdateFirstAidUseCase>(
  (ref) =>
      CoachUpdateFirstAidUseCase(ref.watch(coachProfileRepositoryProvider)),
);

final ownerUpdateCoachComplianceUseCaseProvider =
    Provider<OwnerUpdateCoachComplianceUseCase>(
      (ref) => OwnerUpdateCoachComplianceUseCase(
        ref.watch(coachProfileRepositoryProvider),
      ),
    );

final verifyCoachComplianceUseCaseProvider =
    Provider<VerifyCoachComplianceUseCase>(
      (ref) => VerifyCoachComplianceUseCase(
        ref.watch(coachProfileRepositoryProvider),
      ),
    );

// ── Stream providers ───────────────────────────────────────────────────────

/// A single coach profile by admin UID, streamed live.
final coachProfileProvider = StreamProvider.family<CoachProfile?, String>(
  (ref, adminUserId) =>
      ref.watch(coachProfileRepositoryProvider).watchById(adminUserId),
);

/// All coach profiles, live (owner-only use).
final coachProfileListProvider = StreamProvider<List<CoachProfile>>(
  (ref) => ref.watch(coachProfileRepositoryProvider).watchAll(),
);
