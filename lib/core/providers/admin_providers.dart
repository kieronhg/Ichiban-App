import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/admin_user.dart';
import '../../domain/entities/app_setup.dart';
import '../../domain/use_cases/admin/create_admin_user_use_case.dart';
import '../../domain/use_cases/admin/deactivate_admin_user_use_case.dart';
import '../../domain/use_cases/admin/delete_admin_user_use_case.dart';
import '../../domain/use_cases/admin/demote_to_coach_use_case.dart';
import '../../domain/use_cases/admin/get_admin_user_use_case.dart';
import '../../domain/use_cases/admin/promote_to_owner_use_case.dart';
import '../../domain/use_cases/admin/reactivate_admin_user_use_case.dart';
import '../../domain/use_cases/admin/update_admin_user_use_case.dart';
import 'repository_providers.dart';

// ── Use case providers ─────────────────────────────────────────────────────

final getAdminUserUseCaseProvider = Provider<GetAdminUserUseCase>(
  (ref) => GetAdminUserUseCase(ref.watch(adminUserRepositoryProvider)),
);

final createAdminUserUseCaseProvider = Provider<CreateAdminUserUseCase>(
  (ref) => CreateAdminUserUseCase(ref.watch(adminUserRepositoryProvider)),
);

final updateAdminUserUseCaseProvider = Provider<UpdateAdminUserUseCase>(
  (ref) => UpdateAdminUserUseCase(ref.watch(adminUserRepositoryProvider)),
);

final deactivateAdminUserUseCaseProvider = Provider<DeactivateAdminUserUseCase>(
  (ref) => DeactivateAdminUserUseCase(ref.watch(adminUserRepositoryProvider)),
);

final reactivateAdminUserUseCaseProvider = Provider<ReactivateAdminUserUseCase>(
  (ref) => ReactivateAdminUserUseCase(ref.watch(adminUserRepositoryProvider)),
);

final deleteAdminUserUseCaseProvider = Provider<DeleteAdminUserUseCase>(
  (ref) => DeleteAdminUserUseCase(ref.watch(adminUserRepositoryProvider)),
);

final promoteToOwnerUseCaseProvider = Provider<PromoteToOwnerUseCase>(
  (ref) => PromoteToOwnerUseCase(ref.watch(adminUserRepositoryProvider)),
);

final demoteToCoachUseCaseProvider = Provider<DemoteToCoachUseCase>(
  (ref) => DemoteToCoachUseCase(ref.watch(adminUserRepositoryProvider)),
);

// ── Stream providers ───────────────────────────────────────────────────────

/// All admin users ordered by lastName.
final adminUserListProvider = StreamProvider<List<AdminUser>>(
  (ref) => ref.watch(adminUserRepositoryProvider).watchAll(),
);

/// A single admin user by UID, streamed live.
final adminUserProvider = StreamProvider.family<AdminUser?, String>(
  (ref, uid) => ref.watch(adminUserRepositoryProvider).watchById(uid),
);

// ── App Setup ──────────────────────────────────────────────────────────────

/// Live stream of the app setup document.
/// Emits [AppSetup(setupComplete: false)] while loading or if doc missing.
final appSetupStatusProvider = StreamProvider<AppSetup>(
  (ref) => ref.watch(appSetupRepositoryProvider).watchSetupStatus(),
);
